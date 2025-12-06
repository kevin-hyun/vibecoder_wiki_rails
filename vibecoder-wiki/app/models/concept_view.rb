class ConceptView < ApplicationRecord
  # Associations
  belongs_to :concept
  belongs_to :user, optional: true  # 비로그인 사용자 허용
  
  # Validations
  validates :ip_address, presence: true
  validates :viewed_at, presence: true
  validate :must_have_viewer_identification
  
  # Callbacks
  before_create :set_uuid_primary_key
  after_create :update_concept_view_count
  
  # Scopes
  scope :unique_users, -> { where.not(user: nil).distinct.count(:user_id) }
  scope :anonymous_views, -> { where(user: nil) }
  scope :registered_views, -> { where.not(user: nil) }
  scope :recent, -> { order(viewed_at: :desc) }
  scope :today, -> { where(viewed_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(viewed_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(viewed_at: 1.month.ago..Time.current) }
  
  # PostgreSQL 집계 함수 활용
  def self.analytics_summary
    return {} unless table_exists?
    
    {
      total_views: count,
      unique_users: where.not(user: nil).distinct.count(:user_id),
      unique_ips: distinct.count(:ip_address),
      anonymous_views: anonymous_views.count,
      registered_views: registered_views.count,
      views_today: today.count,
      views_this_week: this_week.count,
      views_this_month: this_month.count
    }
  end
  
  # 개념별 조회 통계
  def self.concept_view_stats(concept)
    concept_views = where(concept: concept)
    
    {
      total_views: concept_views.count,
      unique_users: concept_views.where.not(user: nil).distinct.count(:user_id),
      unique_ips: concept_views.distinct.count(:ip_address),
      anonymous_ratio: (concept_views.anonymous_views.count.to_f / concept_views.count * 100).round(1),
      daily_views: concept_views.group_by_day(:viewed_at, last: 30).count,
      hourly_pattern: hourly_view_pattern(concept),
      return_visitors: return_visitor_count(concept)
    }
  end
  
  # 시간대별 조회 패턴 (PostgreSQL 시간 함수)
  def self.hourly_view_pattern(concept = nil)
    query = concept ? where(concept: concept) : self
    
    query.connection.select_all(
      "SELECT EXTRACT(hour FROM viewed_at) as hour,
              COUNT(*) as view_count
       FROM concept_views 
       #{'WHERE concept_id = $1' if concept}
       GROUP BY EXTRACT(hour FROM viewed_at)
       ORDER BY hour",
      concept ? [concept.id] : []
    ).to_a.map { |row| [row['hour'].to_i, row['view_count'].to_i] }.to_h
  end
  
  # 재방문자 분석
  def self.return_visitor_count(concept)
    where(concept: concept)
      .where.not(user: nil)
      .group(:user_id)
      .having('COUNT(*) > 1')
      .count
      .size
  end
  
  # 사용자 조회 이력
  def self.user_view_history(user, limit = 20)
    return [] unless user
    
    where(user: user)
      .joins(:concept)
      .order(viewed_at: :desc)
      .limit(limit)
      .select('concept_views.*, concepts.title, concepts.category, concepts.level')
  end
  
  # IP별 조회 패턴 (어뷰징 탐지용)
  def self.suspicious_ip_analysis
    connection.select_all(
      "SELECT ip_address,
              COUNT(*) as view_count,
              COUNT(DISTINCT concept_id) as unique_concepts,
              MIN(viewed_at) as first_view,
              MAX(viewed_at) as last_view,
              COUNT(DISTINCT user_id) as unique_users
       FROM concept_views 
       WHERE viewed_at >= CURRENT_DATE - INTERVAL '1 day'
       GROUP BY ip_address
       HAVING COUNT(*) > 100 OR 
              (COUNT(*) > 20 AND COUNT(DISTINCT concept_id) < 3)
       ORDER BY view_count DESC"
    ).to_a
  end
  
  # 지역별 조회 분석 (IP 기반 - 간단한 추정)
  def self.geographic_distribution
    # 실제로는 GeoIP 서비스나 MaxMind DB 사용 권장
    ip_ranges = {
      'KR' => /^(210\.178\.|121\.125\.|175\.203\.)/,  # 한국 IP 대역 예시
      'US' => /^(173\.252\.|31\.13\.)/,
      'JP' => /^(133\.201\.|202\.248\.)/
    }
    
    results = {}
    distinct.pluck(:ip_address).each do |ip|
      country = ip_ranges.find { |country, pattern| ip.match?(pattern) }&.first || 'Unknown'
      results[country] = (results[country] || 0) + 1
    end
    
    results
  end
  
  # 트래픽 예측 (PostgreSQL 시계열 분석)
  def self.traffic_forecast(concept, days_ahead = 7)
    # 최근 30일 데이터를 기반으로 단순 선형 예측
    recent_data = where(concept: concept)
                 .where('viewed_at >= ?', 30.days.ago)
                 .group_by_day(:viewed_at)
                 .count
    
    return {} if recent_data.size < 7
    
    # 단순 이동평균 기반 예측
    values = recent_data.values
    avg_daily_views = values.sum.to_f / values.size
    trend = calculate_trend(values)
    
    forecast = {}
    (1..days_ahead).each do |day|
      date = Date.current + day.days
      predicted_views = [avg_daily_views + (trend * day), 0].max.round
      forecast[date] = predicted_views
    end
    
    forecast
  end
  
  # 개념 인기도 점수 계산
  def popularity_score
    # 조회 시점, 사용자 유형, 체류시간 등을 종합한 점수
    base_score = 1.0
    
    # 등록 사용자 가중치
    base_score *= 1.5 if user.present?
    
    # 최신성 가중치 (최근 조회일수록 높은 점수)
    days_ago = (Time.current - viewed_at) / 1.day
    recency_weight = [1.0 - (days_ago / 30.0), 0.1].max
    base_score *= recency_weight
    
    # 희소성 가중치 (적게 본 개념일수록 높은 점수)
    concept_popularity = concept.view_count
    if concept_popularity < 10
      base_score *= 2.0  # 새로운 개념 보너스
    elsif concept_popularity > 1000
      base_score *= 0.8  # 너무 인기 있는 개념은 점수 감소
    end
    
    base_score.round(3)
  end
  
  # 사용자별 관심 카테고리 분석
  def self.user_interest_analysis(user)
    return {} unless user
    
    user_views = where(user: user).joins(:concept)
    
    {
      total_views: user_views.count,
      category_preferences: user_views.group('concepts.category').count,
      level_preferences: user_views.group('concepts.level').count,
      most_viewed_concepts: user_views.joins(:concept)
                                     .group('concepts.title')
                                     .order('COUNT(*) DESC')
                                     .limit(5)
                                     .count,
      view_frequency: calculate_user_view_frequency(user),
      preferred_time: user_views.connection.select_value(
        "SELECT EXTRACT(hour FROM viewed_at) as hour
         FROM concept_views 
         WHERE user_id = '#{user.id}'
         GROUP BY EXTRACT(hour FROM viewed_at)
         ORDER BY COUNT(*) DESC
         LIMIT 1"
      )&.to_i
    }
  end
  
  private
  
  def set_uuid_primary_key
    self.id = SecureRandom.uuid if id.blank?
  end
  
  def must_have_viewer_identification
    # IP 주소는 항상 있어야 함 (익명 사용자 추적용)
    if ip_address.blank?
      errors.add(:ip_address, 'IP 주소가 필요해요')
    end
  end
  
  def update_concept_view_count
    # 개념의 view_count는 별도 로직에서 업데이트 (중복 방지 포함)
    # concept.increment_view_count! 메소드에서 처리
  end
  
  def self.calculate_trend(values)
    return 0 if values.size < 2
    
    n = values.size
    x_avg = (n - 1).to_f / 2
    y_avg = values.sum.to_f / n
    
    numerator = values.each_with_index.sum { |y, x| (x - x_avg) * (y - y_avg) }
    denominator = values.each_with_index.sum { |_, x| (x - x_avg) ** 2 }
    
    denominator.zero? ? 0 : numerator / denominator
  end
  
  def self.calculate_user_view_frequency(user)
    user_views = where(user: user).order(:viewed_at)
    return 0 if user_views.count < 2
    
    dates = user_views.pluck(:viewed_at).map(&:to_date).uniq
    return 0 if dates.size < 2
    
    first_date = dates.first
    last_date = dates.last
    days_span = (last_date - first_date).to_i
    
    return 0 if days_span.zero?
    
    (dates.size.to_f / days_span * 7).round(2)  # 주간 평균 조회일 수
  end
end