class Concept < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged
  
  # Associations
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by'
  has_many :explanations, dependent: :destroy
  has_many :concept_tags, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :concept_views, dependent: :destroy
  has_many :user_activities, as: :target, dependent: :destroy
  
  # Validations
  validates :title, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :simple_definition, presence: true, length: { maximum: 200 }
  validates :description, length: { maximum: 1000 }
  validates :category, presence: true, inclusion: { 
    in: %w[it startup ui business],
    message: "카테고리는 it, startup, ui, business 중 하나여야 해요"
  }
  validates :level, presence: true, inclusion: { 
    in: 1..3,
    message: "레벨은 1(초급), 2(중급), 3(고급) 중 하나여야 해요"
  }
  validates :view_count, numericality: { greater_than_or_equal_to: 0 }
  validates :average_rating, numericality: { in: 0.0..5.0 }
  
  # Callbacks
  before_create :set_uuid_primary_key
  after_create :create_initial_activity
  after_update :update_search_vector, if: :saved_change_to_searchable_content?
  
  # Scopes - PostgreSQL 최적화
  scope :verified, -> { where(is_verified: true) }
  scope :popular, -> { where(is_popular: true) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :by_level, ->(level) { where(level: level) if level.present? }
  scope :recent, -> { order(created_at: :desc) }
  scope :most_viewed, -> { order(view_count: :desc) }
  scope :top_rated, -> { order(average_rating: :desc, view_count: :desc) }
  scope :beginner_friendly, -> { where(level: 1, is_verified: true) }
  
  # PostgreSQL Full-Text Search - 비전공자 친화적 검색
  scope :search, ->(query) {
    return all if query.blank?
    
    # 한국어 + 영어 혼합 검색 지원
    where(
      "to_tsvector('korean', title || ' ' || simple_definition || ' ' || coalesce(description, '')) @@ plainto_tsquery('korean', ?) OR 
       title ILIKE ? OR 
       simple_definition ILIKE ?",
      query, "%#{query}%", "%#{query}%"
    ).order(
      Arel.sql("ts_rank(to_tsvector('korean', title || ' ' || simple_definition || ' ' || coalesce(description, '')), plainto_tsquery('korean', '#{ActiveRecord::Base.sanitize_sql(query)}')) DESC")
    )
  }
  
  # PostgreSQL Array 활용 - 관련 태그 검색
  scope :with_tags, ->(tags) {
    joins(:concept_tags).where(concept_tags: { tag: tags }).distinct
  }
  
  # 카테고리별 분류 메소드
  def self.categories_with_emoji
    {
      'it' => '💻 IT 기초',
      'startup' => '🚀 창업', 
      'ui' => '🎨 UI/UX',
      'business' => '💼 비즈니스'
    }
  end
  
  def category_with_emoji
    self.class.categories_with_emoji[category] || '📚 일반'
  end
  
  def level_with_emoji
    stars = '⭐' * level
    difficulty = case level
                when 1 then '초급 (쉬워요)'
                when 2 then '중급 (보통이에요)' 
                when 3 then '고급 (어려워요)'
                else '난이도 미정'
                end
    "#{stars} #{difficulty}"
  end
  
  # 통계 메소드들
  def total_explanations
    explanations.count
  end
  
  def best_explanations
    explanations.where(is_best_explanation: true)
  end
  
  def helpful_explanations_ratio
    return 0 if explanations.empty?
    
    helpful_votes = explanations.joins(:votes)
                              .where(votes: { vote_type: 'helpful' })
                              .count
    total_votes = explanations.joins(:votes).count
    
    return 0 if total_votes.zero?
    (helpful_votes.to_f / total_votes * 100).round(1)
  end
  
  # 조회수 증가 (중복 방지 포함)
  def increment_view_count!(user = nil, ip_address = nil)
    # 1시간 내 같은 사용자/IP 중복 조회 방지
    recent_view = concept_views.where(
      user: user,
      ip_address: ip_address,
      created_at: 1.hour.ago..Time.current
    ).exists?
    
    return if recent_view
    
    # PostgreSQL의 원자적 증가 (동시성 보장)
    self.class.where(id: id).update_all('view_count = view_count + 1')
    
    # 조회 기록 저장
    concept_views.create!(
      user: user,
      ip_address: ip_address,
      viewed_at: Time.current
    )
    
    # 실시간 업데이트 (Supabase)
    broadcast_view_count_update
  end
  
  # 평균 평점 계산 (PostgreSQL 집계 함수 활용)
  def calculate_average_rating!
    avg_rating = explanations.joins(:votes)
                           .where(votes: { vote_type: 'helpful' })
                           .group('explanations.id')
                           .average('explanations.helpfulness_score')
                           .values
                           .sum / explanations.count.to_f rescue 0.0
    
    update_column(:average_rating, avg_rating.round(2))
  end
  
  # 관련 개념 찾기 (PostgreSQL 유사도 검색)
  def related_concepts(limit = 4)
    self.class
        .where.not(id: id)
        .where(category: category)
        .where(level: [level - 1, level, level + 1].select(&:positive?))
        .most_viewed
        .limit(limit)
  end
  
  # 태그 관리
  def tag_names
    concept_tags.pluck(:tag)
  end
  
  def add_tags!(tag_names)
    Array(tag_names).each do |tag_name|
      concept_tags.find_or_create_by(tag: tag_name.strip.downcase) do |concept_tag|
        concept_tag.id = SecureRandom.uuid
      end
    end
  end
  
  # SEO 친화적 메소드
  def meta_description
    simple_definition.presence || "#{title}에 대한 쉬운 설명을 바이브코더 위키에서 확인해보세요."
  end
  
  def should_generate_new_friendly_id?
    title_changed?
  end
  
  # 실시간 알림용
  def broadcast_view_count_update
    # Supabase realtime으로 조회수 업데이트 브로드캐스트
    ActionCable.server.broadcast(
      "concept_#{id}",
      {
        type: 'view_count_updated',
        view_count: view_count,
        concept_id: id
      }
    )
  end
  
  # PostgreSQL JSONB 활용 - 메타데이터 저장
  def metadata
    user_activities.where(activity_type: 'concept_metadata_updated')
                  .last&.metadata || {}
  end
  
  def update_metadata!(new_metadata)
    user_activities.create!(
      activity_type: 'concept_metadata_updated',
      metadata: new_metadata,
      points_earned: 0
    )
  end
  
  private
  
  def set_uuid_primary_key
    self.id = SecureRandom.uuid if id.blank?
  end
  
  def create_initial_activity
    user_activities.create!(
      user: creator,
      activity_type: 'concept_created',
      points_earned: 5
    )
  end
  
  def saved_change_to_searchable_content?
    saved_change_to_title? || saved_change_to_simple_definition? || saved_change_to_description?
  end
  
  def update_search_vector
    # PostgreSQL의 tsvector 업데이트 (백그라운드 작업으로 처리 가능)
    UpdateSearchVectorJob.perform_later(self) if defined?(UpdateSearchVectorJob)
  end
end