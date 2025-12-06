class RealtimeNotificationService
  include ActiveModel::Model
  
  # 실시간 알림 서비스 (Supabase + ActionCable)
  
  def self.broadcast_new_explanation(explanation)
    # Supabase 실시간으로 새 설명 알림
    concept_id = explanation.concept_id
    
    # ActionCable을 통한 즉시 알림
    ActionCable.server.broadcast(
      "concept_#{concept_id}",
      {
        type: 'new_explanation',
        explanation_id: explanation.id,
        author_name: explanation.author.display_name,
        content_preview: explanation.content.truncate(50),
        concept_title: explanation.concept.title,
        timestamp: explanation.created_at.iso8601,
        message: generate_new_explanation_message(explanation)
      }
    )
    
    # Supabase를 통한 데이터베이스 실시간 동기화는 자동으로 처리됨
    Rails.logger.info "Broadcasted new explanation #{explanation.id} for concept #{concept_id}"
  end
  
  def self.broadcast_vote_update(vote)
    explanation = vote.explanation
    concept_id = explanation.concept_id
    
    # 투표 결과 실시간 업데이트
    ActionCable.server.broadcast(
      "concept_#{concept_id}",
      {
        type: 'vote_updated',
        explanation_id: explanation.id,
        vote_type: vote.vote_type,
        helpful_count: explanation.helpful_votes_count,
        difficult_count: explanation.difficult_votes_count,
        helpfulness_score: explanation.helpfulness_score,
        voter_name: vote.voter_display_name,
        message: generate_vote_message(vote),
        timestamp: vote.created_at.iso8601
      }
    )
    
    # 전체 사이트 통계 업데이트 (관리자용)
    ActionCable.server.broadcast(
      "admin_dashboard",
      {
        type: 'vote_stats_updated',
        total_votes_today: Vote.today.count,
        helpful_ratio: calculate_helpful_ratio
      }
    )
    
    Rails.logger.info "Broadcasted vote update for explanation #{explanation.id}"
  end
  
  def self.broadcast_best_explanation_selected(explanation)
    concept_id = explanation.concept_id
    
    # 베스트 설명 선정 알림
    ActionCable.server.broadcast(
      "concept_#{concept_id}",
      {
        type: 'best_explanation_selected',
        explanation_id: explanation.id,
        author_name: explanation.author.display_name,
        concept_title: explanation.concept.title,
        message: "⭐ #{explanation.author.display_name}님의 설명이 베스트로 선정되었어요!",
        timestamp: Time.current.iso8601
      }
    )
    
    # 작성자에게 개인 알림
    ActionCable.server.broadcast(
      "user_#{explanation.author_id}",
      {
        type: 'personal_achievement',
        title: '🎉 베스트 설명 선정!',
        message: "\"#{explanation.concept.title}\" 설명이 베스트로 선정되었어요! +10점",
        points_earned: 10,
        explanation_id: explanation.id,
        timestamp: Time.current.iso8601
      }
    )
    
    Rails.logger.info "Broadcasted best explanation selection for #{explanation.id}"
  end
  
  def self.broadcast_concept_view_update(concept)
    # 개념 조회수 실시간 업데이트
    ActionCable.server.broadcast(
      "concept_#{concept.id}",
      {
        type: 'view_count_updated',
        concept_id: concept.id,
        view_count: concept.view_count,
        formatted_count: number_with_delimiter(concept.view_count),
        timestamp: Time.current.iso8601
      }
    )
    
    # 인기 개념 실시간 랭킹 업데이트
    if concept.view_count % 10 == 0  # 10회마다 랭킹 업데이트
      broadcast_popular_concepts_update
    end
  end
  
  def self.broadcast_user_activity(activity)
    user_id = activity.user_id
    
    # 사용자별 활동 알림
    ActionCable.server.broadcast(
      "user_#{user_id}",
      {
        type: 'activity_logged',
        activity_type: activity.activity_type,
        points_earned: activity.points_earned,
        message: activity.activity_message,
        icon: activity.activity_icon,
        timestamp: activity.created_at.iso8601
      }
    )
    
    # 레벨업 체크 및 알림
    check_and_broadcast_level_up(activity.user)
  end
  
  def self.broadcast_popular_concepts_update
    popular_concepts = Concept.joins(:concept_views)
                             .where(concept_views: { created_at: 1.hour.ago..Time.current })
                             .group('concepts.id')
                             .order('COUNT(concept_views.id) DESC')
                             .limit(5)
                             .pluck(:id, :title, 'COUNT(concept_views.id)')
    
    ActionCable.server.broadcast(
      "popular_concepts",
      {
        type: 'popular_concepts_updated',
        concepts: popular_concepts.map do |id, title, count|
          {
            id: id,
            title: title,
            views_last_hour: count,
            url: Rails.application.routes.url_helpers.concept_path(id)
          }
        end,
        timestamp: Time.current.iso8601
      }
    )
  end
  
  def self.broadcast_site_statistics
    # 실시간 사이트 통계 (관리자 대시보드용)
    stats = {
      type: 'site_stats_updated',
      data: {
        total_concepts: Concept.count,
        total_explanations: Explanation.count,
        total_votes_today: Vote.today.count,
        active_users_today: User.joins(:user_activities)
                               .where(user_activities: { created_at: Date.current.beginning_of_day..Date.current.end_of_day })
                               .distinct
                               .count,
        helpful_ratio: calculate_helpful_ratio,
        top_categories: Concept.group(:category).count,
        recent_activities: recent_activities_summary
      },
      timestamp: Time.current.iso8601
    }
    
    ActionCable.server.broadcast("admin_dashboard", stats)
  end
  
  # 사용자 연결 상태 관리
  def self.user_connected(user_id)
    ActionCable.server.broadcast(
      "user_presence",
      {
        type: 'user_connected',
        user_id: user_id,
        timestamp: Time.current.iso8601
      }
    )
  end
  
  def self.user_disconnected(user_id)
    ActionCable.server.broadcast(
      "user_presence",
      {
        type: 'user_disconnected', 
        user_id: user_id,
        timestamp: Time.current.iso8601
      }
    )
  end
  
  # 비전공자 친화적 실시간 도움말
  def self.broadcast_beginner_tip
    tips = [
      "💡 설명할 때 일상적인 비유를 사용하면 더 이해하기 쉬워져요!",
      "🤝 다른 분들의 설명에 '도움됐어요' 투표로 응원해주세요!",
      "📚 북마크 기능으로 나중에 다시 보고 싶은 개념을 저장해보세요!",
      "⭐ 베스트 설명은 커뮤니티 투표로 선정돼요!",
      "🔍 검색할 때 한글로도, 영어로도 찾을 수 있어요!"
    ]
    
    ActionCable.server.broadcast(
      "beginner_tips",
      {
        type: 'beginner_tip',
        tip: tips.sample,
        timestamp: Time.current.iso8601
      }
    )
  end
  
  private
  
  def self.generate_new_explanation_message(explanation)
    author = explanation.author.display_name
    concept = explanation.concept.title
    
    messages = [
      "💬 #{author}님이 \"#{concept}\"에 새로운 설명을 추가했어요!",
      "🎉 \"#{concept}\" 개념에 새로운 관점의 설명이 등록되었어요!",
      "✨ #{author}님의 쉬운 설명을 확인해보세요!"
    ]
    
    messages.sample
  end
  
  def self.generate_vote_message(vote)
    if vote.vote_type == 'helpful'
      [
        "👍 누군가 이 설명이 도움됐다고 했어요!",
        "🎉 좋은 설명에 투표해주셔서 감사해요!",
        "💡 이해하기 쉬운 설명이네요!"
      ].sample
    else
      [
        "💭 더 쉬운 설명이 필요하다는 의견이 있어요",
        "📝 조금 더 자세한 설명을 기다려봐요",
        "🤔 다른 방식으로 설명해주실 분이 계실까요?"
      ].sample
    end
  end
  
  def self.calculate_helpful_ratio
    return 0 if Vote.count.zero?
    
    helpful_count = Vote.helpful.count
    total_count = Vote.count
    
    (helpful_count.to_f / total_count * 100).round(1)
  end
  
  def self.check_and_broadcast_level_up(user)
    level_info = UserActivity.calculate_user_level(user)
    total_points = user.user_activities.sum(:points_earned)
    
    # 레벨업 감지 (이전 포인트와 비교)
    previous_level = calculate_level_from_points(total_points - user.user_activities.last.points_earned)
    current_level = level_info[:current_level][:level]
    
    if current_level > previous_level
      ActionCable.server.broadcast(
        "user_#{user.id}",
        {
          type: 'level_up',
          new_level: current_level,
          level_name: level_info[:current_level][:name],
          message: "🎉 레벨업! #{level_info[:current_level][:name]}이 되었어요!",
          total_points: total_points,
          timestamp: Time.current.iso8601
        }
      )
    end
  end
  
  def self.calculate_level_from_points(points)
    case points
    when 0..49 then 1
    when 50..149 then 2  
    when 150..299 then 3
    when 300..599 then 4
    else 5
    end
  end
  
  def self.recent_activities_summary
    UserActivity.recent
                .limit(10)
                .includes(:user)
                .map do |activity|
      {
        user_name: activity.user.display_name,
        activity_type: activity.activity_type,
        points: activity.points_earned,
        time_ago: time_ago_in_words(activity.created_at)
      }
    end
  end
  
  def self.number_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
  
  def self.time_ago_in_words(time)
    # 간단한 시간차이 계산 (ActionView::Helpers::DateHelper 대신)
    seconds = Time.current - time
    
    case seconds
    when 0..59
      "방금 전"
    when 60..3599
      "#{(seconds / 60).to_i}분 전"
    when 3600..86399  
      "#{(seconds / 3600).to_i}시간 전"
    else
      "#{(seconds / 86400).to_i}일 전"
    end
  end
end