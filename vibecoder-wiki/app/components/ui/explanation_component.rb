class Ui::ExplanationComponent < ViewComponent::Base
  attr_reader :explanation, :concept, :current_user, :show_actions, :compact_mode
  
  def initialize(explanation:, concept:, current_user: nil, show_actions: true, compact_mode: false)
    @explanation = explanation
    @concept = concept
    @current_user = current_user
    @show_actions = show_actions
    @compact_mode = compact_mode
  end
  
  private
  
  def author_display_name
    explanation.author&.display_name || "익명"
  end
  
  def author_avatar_url
    explanation.author&.photo_url || "https://ui-avatars.com/api/?name=#{CGI.escape(author_display_name)}&background=6366f1&color=fff"
  end
  
  def difficulty_badge_class
    case explanation.difficulty_level
    when 'beginner'
      "bg-green-100 text-green-800"
    when 'intermediate'
      "bg-yellow-100 text-yellow-800"
    when 'advanced'
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end
  
  def difficulty_text
    case explanation.difficulty_level
    when 'beginner'
      "🌱 초보자용"
    when 'intermediate'
      "📚 중급자용"
    when 'advanced'
      "🎓 고급자용"
    else
      "📝 일반"
    end
  end
  
  def helpful_votes_count
    explanation.votes.where(vote_type: 'helpful').count
  end
  
  def difficult_votes_count
    explanation.votes.where(vote_type: 'difficult').count
  end
  
  def current_user_vote
    return nil unless current_user
    explanation.votes.find_by(user: current_user)&.vote_type
  end
  
  def can_edit?
    return false unless current_user
    explanation.author == current_user || current_user.admin?
  end
  
  def can_delete?
    return false unless current_user
    explanation.author == current_user || current_user.admin?
  end
  
  def can_make_best?
    return false unless current_user&.admin?
    !explanation.is_best_explanation?
  end
  
  def formatted_content
    # 간단한 줄바꿈 처리
    explanation.content.gsub(/\n/, '<br>').html_safe
  end
  
  def formatted_analogy
    return nil unless explanation.simple_analogy.present?
    explanation.simple_analogy.gsub(/\n/, '<br>').html_safe
  end
  
  def formatted_example
    return nil unless explanation.example.present?
    explanation.example.gsub(/\n/, '<br>').html_safe
  end
  
  def tags_display
    return [] unless explanation.tags.present?
    explanation.tags.first(5) # 최대 5개만 표시
  end
  
  def tag_color_class(tag)
    case tag
    when '일상비유'
      "bg-blue-100 text-blue-800"
    when '예시포함'
      "bg-green-100 text-green-800"
    when '초보추천'
      "bg-purple-100 text-purple-800"
    when '실무연관'
      "bg-orange-100 text-orange-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end
  
  def vote_button_class(vote_type)
    base_class = "inline-flex items-center px-3 py-1.5 text-sm font-medium rounded-md transition-colors duration-200"
    
    if current_user_vote == vote_type
      case vote_type
      when 'helpful'
        "#{base_class} bg-green-100 text-green-800 border border-green-200"
      when 'difficult'
        "#{base_class} bg-red-100 text-red-800 border border-red-200"
      end
    else
      "#{base_class} bg-white text-gray-600 border border-gray-300 hover:bg-gray-50"
    end
  end
  
  def best_explanation_badge
    return unless explanation.is_best_explanation?
    content_tag :div, class: "absolute top-2 right-2" do
      content_tag :span,
        "⭐ 베스트",
        class: "bg-yellow-500 text-white text-xs font-bold px-2 py-1 rounded-full shadow-sm",
        title: "관리자가 선정한 베스트 설명이에요!"
    end
  end
  
  def author_badge
    return unless explanation.author
    
    if explanation.author.admin?
      content_tag :span, "👑", class: "text-yellow-500", title: "관리자"
    elsif explanation.author.is_premium?
      content_tag :span, "💎", class: "text-purple-500", title: "바이브 마스터"
    end
  end
  
  def vote_count_display(vote_type, count)
    if count > 0
      content_tag :span, count, class: "ml-1 font-semibold"
    else
      content_tag :span, "0", class: "ml-1 text-gray-400"
    end
  end
end