class ConceptTag < ApplicationRecord
  # Associations
  belongs_to :concept
  
  # Validations
  validates :tag, presence: true, length: { minimum: 2, maximum: 20 }
  validates :tag, uniqueness: { scope: :concept_id, message: "같은 개념에 이미 있는 태그예요" }
  validate :tag_format
  
  # Callbacks
  before_validation :normalize_tag
  before_create :set_uuid_primary_key
  
  # Scopes
  scope :popular, -> { 
    joins(:concept)
    .group(:tag)
    .order('COUNT(concepts.id) DESC')
  }
  
  scope :by_category, ->(category) {
    joins(:concept).where(concepts: { category: category })
  }
  
  scope :recent, -> { order(created_at: :desc) }
  
  # PostgreSQL 전용 - 태그 유사도 검색
  scope :similar_to, ->(tag_name) {
    where("similarity(tag, ?) > 0.3", tag_name.downcase.strip)
    .order(Arel.sql("similarity(tag, '#{ActiveRecord::Base.sanitize_sql(tag_name.downcase.strip)}') DESC"))
  }
  
  # 태그 통계 (PostgreSQL 집계 함수 활용)
  def self.tag_statistics
    return {} unless table_exists?
    
    {
      total_unique_tags: distinct.count(:tag),
      most_popular_tags: popular.limit(10).count,
      tags_by_category: joins(:concept)
                       .group('concepts.category', :tag)
                       .count,
      average_tags_per_concept: joins(:concept)
                               .group('concepts.id')
                               .count
                               .values
                               .sum.to_f / Concept.count
    }
  end
  
  # 비전공자 친화적 태그 제안
  def self.suggest_beginner_friendly_tags
    beginner_concepts = joins(:concept).where(concepts: { level: 1 })
    
    {
      '초보추천' => beginner_concepts.where(tag: '초보추천').count,
      '일상비유' => beginner_concepts.where(tag: '일상비유').count,
      '쉬운설명' => beginner_concepts.where(tag: '쉬운설명').count,
      '기초개념' => beginner_concepts.where(tag: '기초개념').count,
      '입문자용' => beginner_concepts.where(tag: '입문자용').count
    }
  end
  
  # 태그별 개념 수
  def concept_count
    ConceptTag.where(tag: tag).count
  end
  
  # 태그의 인기도 (조회수 기준)
  def popularity_score
    ConceptTag.joins(:concept)
             .where(tag: tag)
             .sum('concepts.view_count')
  end
  
  # 태그 클라우드용 데이터
  def self.tag_cloud_data(limit = 50)
    joins(:concept)
      .group(:tag)
      .select('concept_tags.tag, 
               COUNT(concepts.id) as concept_count,
               SUM(concepts.view_count) as total_views,
               AVG(concepts.average_rating) as avg_rating')
      .order('concept_count DESC, total_views DESC')
      .limit(limit)
      .map do |tag_data|
        {
          name: tag_data.tag,
          count: tag_data.concept_count,
          views: tag_data.total_views,
          rating: tag_data.avg_rating&.round(1),
          size: calculate_tag_size(tag_data.concept_count),
          color: calculate_tag_color(tag_data.avg_rating || 0)
        }
      end
  end
  
  # 카테고리별 인기 태그
  def self.popular_by_category(category, limit = 10)
    by_category(category)
      .group(:tag)
      .order('COUNT(concept_tags.id) DESC')
      .limit(limit)
      .count
  end
  
  # 태그 자동완성 (PostgreSQL trigram 활용)
  def self.autocomplete(query, limit = 10)
    return [] if query.blank?
    
    where("tag % ?", query.downcase.strip)  # PostgreSQL % 연산자 (유사도)
      .order(Arel.sql("similarity(tag, '#{ActiveRecord::Base.sanitize_sql(query.downcase.strip)}') DESC"))
      .distinct
      .limit(limit)
      .pluck(:tag)
  end
  
  # 관련 태그 찾기
  def related_tags(limit = 5)
    # 같은 개념들에서 함께 사용되는 태그들
    ConceptTag.joins("JOIN concept_tags ct2 ON concept_tags.concept_id = ct2.concept_id")
             .where("ct2.tag = ? AND concept_tags.tag != ?", tag, tag)
             .group('concept_tags.tag')
             .order('COUNT(concept_tags.tag) DESC')
             .limit(limit)
             .pluck('concept_tags.tag')
  end
  
  # 태그의 트렌드 분석 (시간별)
  def trend_data(days = 30)
    ConceptTag.joins(:concept)
             .where(tag: tag)
             .where('concepts.created_at >= ?', days.days.ago)
             .group_by_day('concepts.created_at')
             .count
  end
  
  # 태그 색상 계산 (평점 기준)
  def color_class
    avg_rating = ConceptTag.joins(:concept)
                          .where(tag: tag)
                          .average('concepts.average_rating') || 0
    
    case avg_rating
    when 0..2
      'bg-red-100 text-red-800'
    when 2..3.5
      'bg-yellow-100 text-yellow-800'  
    when 3.5..4.5
      'bg-blue-100 text-blue-800'
    else
      'bg-green-100 text-green-800'
    end
  end
  
  private
  
  def set_uuid_primary_key
    self.id = SecureRandom.uuid if id.blank?
  end
  
  def normalize_tag
    self.tag = tag.strip.downcase if tag.present?
  end
  
  def tag_format
    if tag.present?
      unless tag.match?(/\A[a-zA-Z0-9가-힣]+\z/)
        errors.add(:tag, '태그는 한글, 영문, 숫자만 사용할 수 있어요 (공백이나 특수문자 불가)')
      end
      
      if tag.match?(/^\d+$/)
        errors.add(:tag, '태그는 숫자만으로는 만들 수 없어요')
      end
    end
  end
  
  def self.calculate_tag_size(count)
    case count
    when 1..2
      'text-sm'
    when 3..5  
      'text-base'
    when 6..10
      'text-lg'
    when 11..20
      'text-xl'
    else
      'text-2xl'
    end
  end
  
  def self.calculate_tag_color(rating)
    case rating
    when 0..2
      '#ef4444'  # red
    when 2..3.5
      '#f59e0b'  # amber
    when 3.5..4.5
      '#3b82f6'  # blue
    else
      '#10b981'  # emerald
    end
  end
end