class Ui::ConceptCardComponent < ViewComponent::Base
  attr_reader :concept, :show_bookmark, :current_user
  
  def initialize(concept:, current_user: nil, show_bookmark: true)
    @concept = concept
    @current_user = current_user
    @show_bookmark = show_bookmark
  end
  
  private
  
  def difficulty_badge_class
    case concept.level
    when 1
      "bg-green-100 text-green-800 border-green-200"
    when 2  
      "bg-yellow-100 text-yellow-800 border-yellow-200"
    when 3
      "bg-red-100 text-red-800 border-red-200"
    else
      "bg-gray-100 text-gray-800 border-gray-200"
    end
  end
  
  def difficulty_text
    case concept.level
    when 1
      "⭐ 초급"
    when 2
      "⭐⭐ 중급"
    when 3  
      "⭐⭐⭐ 고급"
    else
      "난이도 미정"
    end
  end
  
  def category_badge_class
    case concept.category
    when 'it'
      "bg-blue-100 text-blue-800"
    when 'startup'
      "bg-purple-100 text-purple-800"
    when 'ui'
      "bg-pink-100 text-pink-800"
    when 'business'
      "bg-orange-100 text-orange-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end
  
  def category_text
    case concept.category
    when 'it'
      "💻 IT 기초"
    when 'startup'
      "🚀 창업"
    when 'ui'
      "🎨 UI/UX"
    when 'business'
      "💼 비즈니스"
    else
      "📚 일반"
    end
  end
  
  def truncated_definition
    return "" unless concept.simple_definition.present?
    
    if concept.simple_definition.length > 60
      concept.simple_definition.truncate(60)
    else
      concept.simple_definition
    end
  end
  
  def best_explanations_count
    concept.explanations.where(is_best_explanation: true).count
  end
  
  def total_explanations_count
    concept.explanations.count
  end
  
  def is_bookmarked?
    return false unless current_user
    current_user.bookmarks.exists?(concept: concept)
  end
  
  def verification_badge
    return unless concept.is_verified?
    content_tag :div, class: "absolute top-2 right-2" do
      content_tag :span, 
        "✅", 
        class: "bg-green-500 text-white text-xs px-1.5 py-0.5 rounded-full",
        title: "관리자가 검증한 개념이에요"
    end
  end
  
  def popularity_indicator
    return unless concept.is_popular?
    content_tag :div, class: "absolute top-2 left-2" do
      content_tag :span,
        "🔥",
        class: "bg-red-500 text-white text-xs px-1.5 py-0.5 rounded-full",
        title: "인기 개념이에요!"
    end
  end
end