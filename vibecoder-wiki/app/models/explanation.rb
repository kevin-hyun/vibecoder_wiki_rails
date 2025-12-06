class Explanation < ApplicationRecord
  # Associations
  belongs_to :concept
  belongs_to :author, class_name: 'User'
  has_many :votes, dependent: :destroy
  has_many :user_activities, as: :target, dependent: :destroy
  
  # Validations
  validates :content, presence: true, length: { 
    maximum: 300, 
    message: "설명은 300자 이내로 작성해주세요 (비전공자도 쉽게 읽을 수 있도록)" 
  }
  validates :simple_analogy, length: { maximum: 200 }
  validates :example, length: { maximum: 200 }
  validates :difficulty_level, inclusion: { 
    in: %w[beginner intermediate advanced],
    message: "난이도는 beginner, intermediate, advanced 중 하나여야 해요"
  }
  validates :vote_count, :helpfulness_score, :clarity_score, 
            numericality: { greater_than_or_equal_to: 0 }
  
  # PostgreSQL Array 타입 validation
  validate :tags_must_be_array
  
  # Callbacks
  before_create :set_uuid_primary_key
  after_create :create_initial_activity
  after_update :broadcast_best_explanation_update, if: :saved_change_to_is_best_explanation?
  
  # Scopes
  scope :best, -> { where(is_best_explanation: true) }
  scope :by_difficulty, ->(level) { where(difficulty_level: level) if level.present? }
  scope :most_helpful, -> { order(helpfulness_score: :desc, vote_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_analogies, -> { where.not(simple_analogy: [nil, '']) }
  scope :with_examples, -> { where.not(example: [nil, '']) }
  
  # PostgreSQL Full-Text Search
  scope :search, ->(query) {
    return all if query.blank?
    where(
      "to_tsvector('korean', content || ' ' || coalesce(simple_analogy, '') || ' ' || coalesce(example, '')) @@ plainto_tsquery('korean', ?)",
      query
    )
  }
  
  # PostgreSQL Array 검색 (태그)
  scope :with_tags, ->(tag_names) {
    where('tags @> ?', Array(tag_names).to_json) if tag_names.present?
  }
  
  # 비전공자 친화적 메소드들
  def difficulty_with_emoji
    case difficulty_level
    when 'beginner'
      '🌱 초보자용'
    when 'intermediate'
      '📚 중급자용'
    when 'advanced'
      '🎓 고급자용'
    else
      '📝 일반'
    end
  end
  
  def difficulty_color_class
    case difficulty_level
    when 'beginner'
      'bg-green-100 text-green-800'
    when 'intermediate'
      'bg-yellow-100 text-yellow-800'
    when 'advanced'
      'bg-red-100 text-red-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end
  
  # 투표 관련 메소드들
  def helpful_votes_count
    votes.where(vote_type: 'helpful').count
  end
  
  def difficult_votes_count
    votes.where(vote_type: 'difficult').count
  end
  
  def vote_ratio
    return 0 if votes.count.zero?
    (helpful_votes_count.to_f / votes.count * 100).round(1)
  end
  
  def user_vote(user)
    return nil unless user
    votes.find_by(user: user)&.vote_type
  end
  
  def ip_vote(ip_address)
    return nil unless ip_address
    votes.find_by(ip_address: ip_address, user: nil)&.vote_type
  end
  
  # PostgreSQL 원자적 업데이트로 투표 수 계산
  def update_vote_counts!
    helpful_count = votes.where(vote_type: 'helpful').count
    difficult_count = votes.where(vote_type: 'difficult').count
    total_count = votes.count
    
    # 도움됨 점수 계산 (비전공자 친화적)
    new_helpfulness_score = if total_count > 0
                             (helpful_count.to_f / total_count * 100).round
                           else
                             0
                           end
    
    # 명확성 점수 (어려움 투표가 적을수록 높음)
    new_clarity_score = if total_count > 0
                         [100 - (difficult_count.to_f / total_count * 100), 0].max.round
                       else
                         50  # 기본값
                       end
    
    update_columns(
      vote_count: total_count,
      helpfulness_score: new_helpfulness_score,
      clarity_score: new_clarity_score,
      updated_at: Time.current
    )
    
    # 실시간 업데이트
    broadcast_vote_update
  end
  
  # 베스트 설명 선정/해제
  def make_best!
    transaction do
      # 같은 개념의 다른 베스트 설명들 해제
      concept.explanations.where(is_best_explanation: true).update_all(is_best_explanation: false)
      
      # 현재 설명을 베스트로 설정
      update!(is_best_explanation: true)
      
      # 작성자에게 포인트 지급
      author.add_points(10, 'best_explanation_selected', self)
    end
  end
  
  def remove_best!
    update!(is_best_explanation: false)
  end
  
  # 태그 관리 (PostgreSQL Array 활용)
  def add_tag!(tag_name)
    return if tags.include?(tag_name.strip.downcase)
    
    update!(tags: tags + [tag_name.strip.downcase])
  end
  
  def remove_tag!(tag_name)
    update!(tags: tags - [tag_name.strip.downcase])
  end
  
  def has_tag?(tag_name)
    tags.include?(tag_name.strip.downcase)
  end
  
  # 자동 태그 감지 (PostgreSQL 정규식 활용)
  def detect_and_add_tags!
    new_tags = []
    
    # 일상 비유 감지
    if content.match?(/같은|마치|비슷|처럼|예를 들어/i) || simple_analogy.present?
      new_tags << '일상비유'
    end
    
    # 예시 포함 감지
    if content.match?(/예시|예를 들면|가령/i) || example.present?
      new_tags << '예시포함'
    end
    
    # 초보자 친화적 감지
    if content.length <= 200 && !content.match?(/API|HTTP|서버|클라이언트/i)
      new_tags << '초보추천'
    end
    
    # 실무 관련 감지
    if content.match?(/실제로|현실에서|업무에서|실무/i)
      new_tags << '실무연관'
    end
    
    # 기술 용어 많음 감지
    tech_terms = content.scan(/API|HTTP|서버|클라이언트|데이터베이스|프레임워크/i).size
    if tech_terms >= 3
      new_tags << '기술용어많음'
    end
    
    # 새 태그들 추가
    update!(tags: (tags + new_tags).uniq)
  end
  
  # 유사한 설명 찾기 (PostgreSQL 유사도 검색)
  def similar_explanations(limit = 3)
    self.class
        .where.not(id: id)
        .where(concept: concept)
        .joins("JOIN similarity(content, '#{ActiveRecord::Base.sanitize_sql(content)}') AS sim ON true")
        .where('sim > 0.3')
        .order('sim DESC')
        .limit(limit)
  end
  
  # 실시간 알림용
  def broadcast_vote_update
    ActionCable.server.broadcast(
      "concept_#{concept_id}",
      {
        type: 'explanation_vote_updated',
        explanation_id: id,
        helpful_votes: helpful_votes_count,
        difficult_votes: difficult_votes_count,
        helpfulness_score: helpfulness_score
      }
    )
  end
  
  def broadcast_best_explanation_update
    ActionCable.server.broadcast(
      "concept_#{concept_id}",
      {
        type: 'best_explanation_updated',
        explanation_id: id,
        is_best: is_best_explanation
      }
    )
  end
  
  # PostgreSQL JSONB 활용 - 메타데이터
  def analytics_data
    {
      word_count: content.split.size,
      character_count: content.length,
      has_analogy: simple_analogy.present?,
      has_example: example.present?,
      technical_terms_count: content.scan(/API|HTTP|서버|클라이언트|데이터베이스|프레임워크/i).size,
      readability_score: calculate_readability_score
    }
  end
  
  private
  
  def set_uuid_primary_key
    self.id = SecureRandom.uuid if id.blank?
  end
  
  def create_initial_activity
    user_activities.create!(
      user: author,
      activity_type: 'explanation_created',
      points_earned: 2
    )
  end
  
  def tags_must_be_array
    unless tags.is_a?(Array)
      errors.add(:tags, '태그는 배열 형태여야 합니다')
    end
  end
  
  # 비전공자 친화적 가독성 점수 계산
  def calculate_readability_score
    # 간단한 가독성 점수 (0-100)
    score = 100
    
    # 길이 패널티
    score -= (content.length / 300.0 * 20).round if content.length > 150
    
    # 기술 용어 패널티
    tech_terms = content.scan(/API|HTTP|서버|클라이언트|데이터베이스|프레임워크/i).size
    score -= tech_terms * 10
    
    # 일상 비유 보너스
    score += 20 if simple_analogy.present?
    
    # 예시 보너스
    score += 15 if example.present?
    
    [score, 0].max
  end
end