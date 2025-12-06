class Bookmark < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :concept
  
  # Validations
  validates :user_id, uniqueness: { 
    scope: :concept_id, 
    message: "이미 북마크한 개념이에요" 
  }
  
  # Callbacks
  before_create :set_uuid_primary_key
  after_create :increment_bookmark_stats
  after_destroy :decrement_bookmark_stats
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :popular_concepts, -> {
    joins(:concept)
    .group('concepts.id')
    .order('COUNT(bookmarks.id) DESC')
  }
  
  scope :by_category, ->(category) {
    joins(:concept).where(concepts: { category: category })
  }
  
  scope :by_level, ->(level) {
    joins(:concept).where(concepts: { level: level })
  }
  
  # PostgreSQL 집계 함수 활용
  def self.bookmark_statistics
    return {} unless table_exists?
    
    {
      total_bookmarks: count,
      unique_users: distinct.count(:user_id),
      unique_concepts: distinct.count(:concept_id),
      average_bookmarks_per_user: count.to_f / distinct.count(:user_id),
      most_bookmarked_concepts: joins(:concept)
                               .group('concepts.title')
                               .order('COUNT(bookmarks.id) DESC')
                               .limit(10)
                               .count
    }
  end
  
  # 사용자별 북마크 패턴 분석
  def self.user_bookmark_patterns(user)
    return {} unless user
    
    user_bookmarks = where(user: user).joins(:concept)
    
    {
      total_bookmarks: user_bookmarks.count,
      categories_distribution: user_bookmarks.group('concepts.category').count,
      levels_distribution: user_bookmarks.group('concepts.level').count,
      recent_bookmarks: user_bookmarks.recent.limit(5)
                                    .pluck('concepts.title', :created_at),
      bookmark_frequency: calculate_bookmark_frequency(user),
      favorite_category: user_bookmarks.group('concepts.category')
                                      .order('COUNT(*) DESC')
                                      .limit(1)
                                      .count
                                      .keys
                                      .first
    }
  end
  
  # 개념별 북마크 트렌드
  def self.concept_bookmark_trends(concept, days = 30)
    where(concept: concept)
      .where('created_at >= ?', days.days.ago)
      .group_by_day(:created_at)
      .count
  end
  
  # 추천 개념 (북마크 패턴 기반)
  def self.recommended_concepts_for_user(user, limit = 5)
    return Concept.none unless user
    
    # 사용자가 북마크한 개념들과 같은 카테고리의 인기 개념들
    bookmarked_categories = where(user: user)
                           .joins(:concept)
                           .distinct
                           .pluck('concepts.category')
    
    return Concept.none if bookmarked_categories.empty?
    
    # 이미 북마크한 개념 제외하고 추천
    already_bookmarked = where(user: user).pluck(:concept_id)
    
    Concept.where(category: bookmarked_categories)
           .where.not(id: already_bookmarked)
           .joins("LEFT JOIN bookmarks ON concepts.id = bookmarks.concept_id")
           .group('concepts.id')
           .order('COUNT(bookmarks.id) DESC, concepts.view_count DESC')
           .limit(limit)
  end
  
  # 카테고리별 인기 북마크
  def self.popular_by_category(category, limit = 10)
    by_category(category)
      .joins(:concept)
      .group('concepts.id', 'concepts.title')
      .order('COUNT(bookmarks.id) DESC')
      .limit(limit)
      .count
  end
  
  # 북마크 활동 점수 계산
  def activity_score
    # 북마크 생성일부터 현재까지의 활동 점수
    days_since_bookmark = (Time.current - created_at) / 1.day
    concept_popularity = concept.view_count / 100.0  # 조회수 기반 가중치
    
    base_score = 10
    time_decay = [1.0 - (days_since_bookmark / 365.0), 0.1].max  # 시간에 따른 감소
    popularity_bonus = [concept_popularity, 5.0].min  # 최대 5점 보너스
    
    (base_score * time_decay + popularity_bonus).round(2)
  end
  
  # 북마크 폴더링 (향후 확장용)
  def folder_name
    case concept.category
    when 'it'
      '💻 IT 기초 개념'
    when 'startup'
      '🚀 창업 노하우'
    when 'ui'
      '🎨 UI/UX 디자인'
    when 'business'
      '💼 비즈니스 용어'
    else
      '📚 일반 지식'
    end
  end
  
  # 북마크한 개념의 학습 진도율 (가상)
  def learning_progress
    # 사용자가 이 개념을 얼마나 학습했는지 (조회 횟수, 설명 참여 등)
    user_views = concept.concept_views.where(user: user).count
    user_explanations = concept.explanations.where(author: user).count
    user_votes = concept.explanations.joins(:votes).where(votes: { user: user }).count
    
    total_activity = user_views + (user_explanations * 5) + user_votes
    max_expected_activity = 20  # 완전 학습으로 간주되는 활동 수준
    
    [[(total_activity.to_f / max_expected_activity * 100).round, 100].min, 0].max
  end
  
  # 북마크 공유용 데이터
  def sharing_data
    {
      concept_title: concept.title,
      concept_description: concept.simple_definition,
      bookmark_date: created_at.strftime('%Y년 %m월 %d일'),
      category: concept.category_with_emoji,
      level: concept.level_with_emoji,
      url: Rails.application.routes.url_helpers.concept_url(concept),
      user_name: user.display_name
    }
  end
  
  private
  
  def set_uuid_primary_key
    self.id = SecureRandom.uuid if id.blank?
  end
  
  def increment_bookmark_stats
    # 개념의 북마크 수 증가는 별도 컬럼이 없으므로 생략
    # 필요시 concepts 테이블에 bookmarks_count 컬럼 추가 가능
  end
  
  def decrement_bookmark_stats
    # 개념의 북마크 수 감소
  end
  
  def self.calculate_bookmark_frequency(user)
    user_bookmarks = where(user: user).order(:created_at)
    return 0 if user_bookmarks.count < 2
    
    dates = user_bookmarks.pluck(:created_at).map(&:to_date)
    intervals = dates.each_cons(2).map { |a, b| (b - a).to_i }
    
    return 0 if intervals.empty?
    
    average_interval = intervals.sum.to_f / intervals.size
    frequency = 30.0 / average_interval  # 월 평균 북마크 빈도
    
    frequency.round(2)
  end
end