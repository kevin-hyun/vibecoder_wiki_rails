module ApplicationHelper
  include Pagy::Frontend

  # 비전공자 친화적 헬퍼 메소드들
  
  def beginner_friendly_time(time)
    return "알 수 없음" unless time
    
    seconds_ago = Time.current - time
    
    case seconds_ago
    when 0..59
      "방금 전"
    when 60..3599
      "#{(seconds_ago / 60).to_i}분 전"
    when 3600..86399
      "#{(seconds_ago / 3600).to_i}시간 전"
    when 86400..604799
      "#{(seconds_ago / 86400).to_i}일 전"
    else
      time.strftime('%Y년 %m월 %d일')
    end
  end

  def difficulty_badge(level)
    stars = '⭐' * level
    text = case level
           when 1 then '초급 (쉬워요)'
           when 2 then '중급 (보통이에요)'
           when 3 then '고급 (어려워요)'
           else '난이도 미정'
           end
    
    css_class = case level
                when 1 then 'difficulty-beginner'
                when 2 then 'difficulty-intermediate' 
                when 3 then 'difficulty-advanced'
                else 'bg-gray-100 text-gray-800'
                end

    content_tag :span, "#{stars} #{text}", class: "inline-flex items-center px-2 py-1 text-xs font-medium rounded-full #{css_class}"
  end

  def category_badge(category)
    emoji, text, css_class = case category
                            when 'it'
                              ['💻', 'IT 기초', 'bg-blue-100 text-blue-800']
                            when 'startup'
                              ['🚀', '창업', 'bg-purple-100 text-purple-800']
                            when 'ui'
                              ['🎨', 'UI/UX', 'bg-pink-100 text-pink-800']
                            when 'business'
                              ['💼', '비즈니스', 'bg-orange-100 text-orange-800']
                            else
                              ['📚', '일반', 'bg-gray-100 text-gray-800']
                            end

    content_tag :span, "#{emoji} #{text}", class: "inline-flex items-center px-2 py-1 text-xs font-medium rounded-full #{css_class}"
  end

  def vote_type_emoji(vote_type)
    case vote_type
    when 'helpful'
      '👍'
    when 'difficult'
      '🤔'
    else
      '❓'
    end
  end

  def user_level_badge(user)
    return content_tag(:span, '👤 게스트', class: 'text-gray-500') unless user

    level_info = UserActivity.calculate_user_level(user)
    level_name = level_info[:current_level][:name]
    
    css_class = case level_info[:current_level][:level]
                when 1
                  'bg-green-100 text-green-800'
                when 2
                  'bg-blue-100 text-blue-800'
                when 3
                  'bg-purple-100 text-purple-800'
                when 4
                  'bg-yellow-100 text-yellow-800'
                when 5
                  'bg-red-100 text-red-800'
                else
                  'bg-gray-100 text-gray-800'
                end

    content_tag :span, level_name, class: "inline-flex items-center px-2 py-1 text-xs font-medium rounded-full #{css_class}"
  end

  def format_number(number)
    return '0' unless number

    case number
    when 0..999
      number.to_s
    when 1000..999999
      "#{(number / 1000.0).round(1)}K"
    when 1000000..999999999
      "#{(number / 1000000.0).round(1)}M"
    else
      "#{(number / 1000000000.0).round(1)}B"
    end
  end

  def progress_bar(current, total, options = {})
    return '' if total.zero?
    
    percentage = [(current.to_f / total * 100).round, 100].min
    height = options[:height] || 'h-2'
    color = options[:color] || 'bg-indigo-600'
    
    content_tag :div, class: "w-full bg-gray-200 rounded-full #{height}" do
      content_tag :div, '', 
        class: "#{color} #{height} rounded-full transition-all duration-300",
        style: "width: #{percentage}%"
    end
  end

  def flash_message_class(type)
    case type.to_s
    when 'notice', 'success'
      'bg-green-50 border-green-200 text-green-800'
    when 'alert', 'error'
      'bg-red-50 border-red-200 text-red-800'
    when 'warning'
      'bg-yellow-50 border-yellow-200 text-yellow-800'
    else
      'bg-blue-50 border-blue-200 text-blue-800'
    end
  end

  def truncate_words(text, word_limit = 20)
    return '' unless text.present?
    
    words = text.split(/\s+/)
    if words.length > word_limit
      words[0...word_limit].join(' ') + '...'
    else
      text
    end
  end

  def beginner_guidance_tooltip(message_type)
    guidance = current_user_or_guest.respond_to?(:provide_beginner_guidance) ? 
               current_user_or_guest.provide_beginner_guidance(message_type) :
               provide_beginner_guidance(message_type)
    
    content_tag :div, 
      guidance,
      class: 'hidden group-hover:block absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-3 py-2 bg-gray-800 text-white text-xs rounded whitespace-nowrap z-10'
  end

  private

  def provide_beginner_guidance(message_type)
    guidance_messages = {
      first_visit: "바이브코더 위키에 오신 걸 환영해요! IT 개념들을 쉬운 언어로 설명해드릴게요.",
      first_explanation: "첫 설명 작성을 준비 중이시군요! 일상 비유를 사용하면 다른 분들이 더 쉽게 이해할 수 있어요.",
      first_vote: "좋은 설명에 투표해주세요! 여러분의 투표가 더 나은 설명을 찾는 데 도움이 됩니다.",
      premium_consideration: "바이브 마스터가 되시면 더 많은 기능을 이용하실 수 있어요!"
    }
    
    guidance_messages[message_type] || "바이브코더 위키와 함께 IT 세상을 탐험해보세요!"
  end
end