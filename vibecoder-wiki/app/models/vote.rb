class Vote < ApplicationRecord
  # Associations
  belongs_to :explanation
  belongs_to :user, optional: true  # 비로그인 사용자 허용
  
  # Validations
  validates :vote_type, presence: true, inclusion: { 
    in: %w[helpful difficult],
    message: "투표는 'helpful'(도움됨) 또는 'difficult'(어려움)이어야 해요"
  }
  validates :reason, length: { maximum: 200 }
  validate :must_have_voter_identification
  validate :unique_vote_per_voter
  
  # Callbacks
  before_create :set_uuid_primary_key
  after_create :update_explanation_counts
  after_destroy :update_explanation_counts
  after_update :update_explanation_counts, if: :saved_change_to_vote_type?
  
  # Scopes
  scope :helpful, -> { where(vote_type: 'helpful') }
  scope :difficult, -> { where(vote_type: 'difficult') }
  scope :by_users, -> { where.not(user: nil) }
  scope :by_anonymous, -> { where(user: nil) }
  scope :recent, -> { order(created_at: :desc) }
  
  # PostgreSQL 집계 함수 활용
  scope :vote_stats, -> {
    group(:vote_type)
    .group_by_day(:created_at)
    .count
  }
  
  # 비전공자 친화적 메소드들
  def vote_type_with_emoji
    case vote_type
    when 'helpful'
      '👍 도움됐어요'
    when 'difficult'
      '😅 어려워요'
    else
      '❓ 알 수 없음'
    end
  end
  
  def voter_display_name
    if user
      user.display_name
    else
      "익명 사용자 (#{ip_address&.last(4) || 'Unknown'})"
    end
  end
  
  def is_anonymous?
    user.nil?
  end
  
  def is_registered_user?
    user.present?
  end
  
  # 투표 변경
  def toggle_vote_type!
    new_type = vote_type == 'helpful' ? 'difficult' : 'helpful'
    update!(vote_type: new_type)
  end
  
  # 투표 이유 분석 (PostgreSQL 텍스트 분석)
  def self.analyze_vote_reasons
    return {} unless table_exists?
    
    helpful_reasons = where(vote_type: 'helpful')
                     .where.not(reason: [nil, ''])
                     .pluck(:reason)
    
    difficult_reasons = where(vote_type: 'difficult')
                       .where.not(reason: [nil, ''])
                       .pluck(:reason)
    
    {
      helpful_keywords: extract_keywords(helpful_reasons),
      difficult_keywords: extract_keywords(difficult_reasons),
      total_votes: count,
      votes_with_reasons: where.not(reason: [nil, '']).count
    }
  end
  
  # IP 기반 투표 통계 (어뷰징 방지)
  def self.ip_vote_analysis
    return {} unless table_exists?
    
    {
      unique_ips: distinct.count(:ip_address),
      anonymous_votes: by_anonymous.count,
      registered_votes: by_users.count,
      suspicious_ips: where('ip_address IS NOT NULL')
                     .group(:ip_address)
                     .having('COUNT(*) > 10')
                     .count
                     .keys
    }
  end
  
  # 시간대별 투표 패턴 (PostgreSQL 시간 함수 활용)
  def self.hourly_vote_pattern
    return {} unless table_exists?
    
    connection.select_all(
      "SELECT EXTRACT(hour FROM created_at) as hour, 
              COUNT(*) as vote_count,
              COUNT(*) FILTER (WHERE vote_type = 'helpful') as helpful_count,
              COUNT(*) FILTER (WHERE vote_type = 'difficult') as difficult_count
       FROM votes 
       WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
       GROUP BY EXTRACT(hour FROM created_at)
       ORDER BY hour"
    ).to_a
  end
  
  # 실시간 투표 알림
  def broadcast_vote_update
    ActionCable.server.broadcast(
      "concept_#{explanation.concept_id}",
      {
        type: 'new_vote',
        explanation_id: explanation_id,
        vote_type: vote_type,
        voter_name: voter_display_name,
        total_helpful: explanation.helpful_votes_count,
        total_difficult: explanation.difficult_votes_count,
        message: generate_vote_message
      }
    )
  end
  
  # Supabase 실시간 이벤트 발생
  def trigger_supabase_realtime
    # Supabase의 실시간 기능을 통해 모든 클라이언트에게 알림
    Rails.logger.info "Vote created: #{vote_type} for explanation #{explanation_id}"
  end
  
  private
  
  def set_uuid_primary_key
    self.id = SecureRandom.uuid if id.blank?
  end
  
  def must_have_voter_identification
    if user.blank? && ip_address.blank?
      errors.add(:base, '투표하려면 로그인하거나 IP 주소가 필요해요')
    end
  end
  
  def unique_vote_per_voter
    existing_vote = if user
                     Vote.where(user: user, explanation: explanation)
                         .where.not(id: id)
                         .exists?
                   else
                     Vote.where(ip_address: ip_address, explanation: explanation)
                         .where(user: nil)
                         .where.not(id: id)
                         .exists?
                   end
    
    if existing_vote
      errors.add(:base, '이미 이 설명에 투표하셨어요. 기존 투표를 변경하시려면 취소 후 다시 투표해주세요.')
    end
  end
  
  def update_explanation_counts
    explanation&.update_vote_counts!
  end
  
  def generate_vote_message
    if vote_type == 'helpful'
      messages = [
        '👍 누군가 이 설명이 도움됐다고 했어요!',
        '🎉 좋은 설명에 투표해주셔서 감사해요!',
        '💡 이해하기 쉬운 설명이네요!'
      ]
    else
      messages = [
        '💭 더 쉬운 설명이 필요하다는 의견이 있어요',
        '📝 조금 더 자세한 설명을 기다려봐요',
        '🤔 다른 방식으로 설명해주실 분이 계실까요?'
      ]
    end
    
    messages.sample
  end
  
  def self.extract_keywords(text_array)
    return [] if text_array.empty?
    
    # 간단한 키워드 추출 (PostgreSQL에서는 더 정교한 분석 가능)
    all_text = text_array.join(' ').downcase
    common_words = %w[이 그 저 를 가 에 의 로 와 과 도 만 까지 부터 하다 되다 있다 없다]
    
    words = all_text.scan(/\w+/).reject { |word| common_words.include?(word) || word.length < 2 }
    words.tally.sort_by { |_, count| -count }.first(10).to_h
  end
end