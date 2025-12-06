class UserActivity < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :target, polymorphic: true, optional: true
  
  # Validations
  validates :activity_type, presence: true, inclusion: { 
    in: %w[explanation_created vote_cast concept_created best_explanation_selected concept_verified preferences_updated concept_metadata_updated],
    message: "지원하지 않는 활동 유형이에요"
  }
  validates :points_earned, numericality: { greater_than_or_equal_to: 0 }
  
  # PostgreSQL JSONB validation
  validates :metadata, presence: true
  validate :metadata_must_be_hash
  
  # Callbacks
  before_create :set_uuid_primary_key
  after_create :update_user_stats
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_activity, ->(type) { where(activity_type: type) }
  scope :with_points, -> { where('points_earned > 0') }
  scope :today, -> { where(created_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(created_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(created_at: 1.month.ago..Time.current) }
  
  # PostgreSQL JSONB 쿼리
  scope :with_metadata_key, ->(key) { where("metadata ? ?", key) }
  scope :with_metadata_value, ->(key, value) { where("metadata ->> ? = ?", key, value.to_s) }
  
  # 활동 통계
  def self.activity_statistics(user = nil)
    query = user ? where(user: user) : self
    
    {
      total_activities: query.count,
      total_points: query.sum(:points_earned),
      activities_by_type: query.group(:activity_type).count,
      points_by_type: query.group(:activity_type).sum(:points_earned),
      daily_activities: query.group_by_day(:created_at, last: 30).count,
      most_active_users: user ? nil : group(:user_id)
                                     .order('COUNT(*) DESC')
                                     .limit(10)
                                     .joins(:user)
                                     .pluck('users.display_name', 'COUNT(*)')
    }
  end
  
  # 사용자 레벨 계산 (게이미피케이션)
  def self.calculate_user_level(user)
    total_points = where(user: user).sum(:points_earned)
    
    level_thresholds = [
      { level: 1, name: '🌱 새싹 멤버', min_points: 0, max_points: 49 },
      { level: 2, name: '📝 활발한 멤버', min_points: 50, max_points: 149 },
      { level: 3, name: '🌟 베테랑 멤버', min_points: 150, max_points: 299 },
      { level: 4, name: '🏆 전문가', min_points: 300, max_points: 599 },
      { level: 5, name: '👑 마스터', min_points: 600, max_points: Float::INFINITY }
    ]
    
    current_level = level_thresholds.find { |l| total_points >= l[:min_points] && total_points <= l[:max_points] }
    next_level = level_thresholds.find { |l| l[:level] == current_level[:level] + 1 }
    
    {
      current_level: current_level,
      next_level: next_level,
      points_to_next: next_level ? next_level[:min_points] - total_points : 0,
      progress_percentage: next_level ? ((total_points - current_level[:min_points]).to_f / (next_level[:min_points] - current_level[:min_points]) * 100).round(1) : 100
    }
  end
  
  # 활동 배지 시스템
  def self.calculate_badges(user)
    activities = where(user: user)
    badges = []
    
    # 설명 작성 배지
    explanation_count = activities.by_activity('explanation_created').count
    if explanation_count >= 50
      badges << { name: '✍️ 설명 마스터', description: '50개 이상의 설명을 작성했어요' }
    elsif explanation_count >= 20
      badges << { name: '📝 설명 전문가', description: '20개 이상의 설명을 작성했어요' }
    elsif explanation_count >= 5
      badges << { name: '🌟 설명 작성자', description: '5개 이상의 설명을 작성했어요' }
    end
    
    # 투표 배지
    vote_count = activities.by_activity('vote_cast').count
    if vote_count >= 100
      badges << { name: '🗳️ 투표 마스터', description: '100번 이상 투표했어요' }
    elsif vote_count >= 50
      badges << { name: '👍 활발한 투표자', description: '50번 이상 투표했어요' }
    end
    
    # 베스트 설명 배지
    best_count = activities.by_activity('best_explanation_selected').count
    if best_count >= 10
      badges << { name: '⭐ 베스트 컬렉터', description: '10개의 베스트 설명을 받았어요' }
    elsif best_count >= 3
      badges << { name: '🏅 베스트 작성자', description: '3개의 베스트 설명을 받았어요' }
    elsif best_count >= 1
      badges << { name: '🌟 첫 베스트', description: '첫 베스트 설명을 받았어요' }
    end
    
    # 연속 활동 배지
    consecutive_days = calculate_consecutive_activity_days(user)
    if consecutive_days >= 30
      badges << { name: '🔥 한달 연속', description: '30일 연속으로 활동했어요' }
    elsif consecutive_days >= 7
      badges << { name: '💪 일주일 연속', description: '7일 연속으로 활동했어요' }
    end
    
    badges
  end
  
  # 활동 유형별 메시지
  def activity_message
    case activity_type
    when 'explanation_created'
      "#{target&.concept&.title}에 새로운 설명을 추가했어요 (+#{points_earned}점)"
    when 'vote_cast'
      vote_type = metadata['vote_type']
      emoji = vote_type == 'helpful' ? '👍' : '🤔'
      "설명에 #{emoji} 투표했어요 (+#{points_earned}점)"
    when 'concept_created'
      "#{target&.title} 개념을 새로 추가했어요 (+#{points_earned}점)"
    when 'best_explanation_selected'
      "설명이 베스트로 선정되었어요! 🎉 (+#{points_earned}점)"
    when 'concept_verified'
      "개념이 관리자에 의해 검증되었어요 ✅ (+#{points_earned}점)"
    else
      "활동 완료 (+#{points_earned}점)"
    end
  end
  
  # 활동 아이콘
  def activity_icon
    case activity_type
    when 'explanation_created'
      '📝'
    when 'vote_cast'
      metadata['vote_type'] == 'helpful' ? '👍' : '🤔'
    when 'concept_created'
      '💡'
    when 'best_explanation_selected'
      '⭐'
    when 'concept_verified'
      '✅'
    else
      '🎯'
    end
  end
  
  # 활동 색상 클래스
  def activity_color_class
    case activity_type
    when 'explanation_created'
      'bg-blue-50 border-blue-200 text-blue-800'
    when 'vote_cast'
      'bg-green-50 border-green-200 text-green-800'
    when 'concept_created'
      'bg-purple-50 border-purple-200 text-purple-800'
    when 'best_explanation_selected'
      'bg-yellow-50 border-yellow-200 text-yellow-800'
    when 'concept_verified'
      'bg-emerald-50 border-emerald-200 text-emerald-800'
    else
      'bg-gray-50 border-gray-200 text-gray-800'
    end
  end
  
  # 주간/월간 활동 리포트
  def self.activity_report(user, period = 'week')
    start_date = period == 'week' ? 1.week.ago : 1.month.ago
    activities = where(user: user, created_at: start_date..Time.current)
    
    {
      period: period,
      total_activities: activities.count,
      total_points: activities.sum(:points_earned),
      activities_by_type: activities.group(:activity_type).count,
      daily_breakdown: activities.group_by_day(:created_at).count,
      achievements: calculate_period_achievements(activities),
      rank_among_users: calculate_user_rank(user, start_date)
    }
  end
  
  # PostgreSQL JSONB 활용 - 복잡한 메타데이터 쿼리
  def self.advanced_analytics
    connection.select_all(
      "SELECT 
         activity_type,
         COUNT(*) as count,
         AVG(points_earned) as avg_points,
         jsonb_object_keys(metadata) as metadata_keys,
         COUNT(DISTINCT user_id) as unique_users
       FROM user_activities 
       WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
       GROUP BY activity_type, jsonb_object_keys(metadata)
       ORDER BY count DESC"
    ).to_a
  end
  
  private
  
  def set_uuid_primary_key
    self.id = SecureRandom.uuid if id.blank?
  end
  
  def metadata_must_be_hash
    unless metadata.is_a?(Hash)
      errors.add(:metadata, '메타데이터는 해시 형태여야 해요')
    end
  end
  
  def update_user_stats
    if points_earned > 0
      user.increment!(:total_votes, points_earned)
    end
  end
  
  def self.calculate_consecutive_activity_days(user)
    activities = where(user: user).order(created_at: :desc)
    return 0 if activities.empty?
    
    consecutive_days = 0
    current_date = Date.current
    
    loop do
      day_activities = activities.where(created_at: current_date.beginning_of_day..current_date.end_of_day)
      if day_activities.exists?
        consecutive_days += 1
        current_date -= 1.day
      else
        break
      end
    end
    
    consecutive_days
  end
  
  def self.calculate_period_achievements(activities)
    achievements = []
    
    # 이번 주/월 첫 활동
    if activities.any?
      achievements << {
        name: '🎯 활동 시작',
        description: '이번 기간 첫 활동을 했어요!'
      }
    end
    
    # 다양한 활동 유형
    if activities.distinct.count(:activity_type) >= 3
      achievements << {
        name: '🌈 다재다능',
        description: '다양한 종류의 활동을 했어요!'
      }
    end
    
    # 포인트 마일스톤
    total_points = activities.sum(:points_earned)
    if total_points >= 100
      achievements << {
        name: '💯 포인트 마스터',
        description: "이번 기간에 #{total_points}점을 획득했어요!"
      }
    end
    
    achievements
  end
  
  def self.calculate_user_rank(user, start_date)
    user_points = where(user: user, created_at: start_date..Time.current).sum(:points_earned)
    better_users = select(:user_id)
                  .where(created_at: start_date..Time.current)
                  .group(:user_id)
                  .having('SUM(points_earned) > ?', user_points)
                  .count
    
    better_users + 1  # 순위는 1부터 시작
  end
end