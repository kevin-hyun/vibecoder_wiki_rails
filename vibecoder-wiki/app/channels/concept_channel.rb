class ConceptChannel < ApplicationCable::Channel
  def subscribed
    concept_id = params[:concept_id]
    
    if concept_id.present? && valid_concept?(concept_id)
      stream_from "concept_#{concept_id}"
      
      # 연결 로그
      Rails.logger.info "User subscribed to concept #{concept_id} channel"
      
      # 연결 확인 메시지 (비전공자 친화적)
      transmit({
        type: 'connection_established',
        message: '실시간 업데이트가 연결되었어요! 새로운 설명이나 투표가 실시간으로 표시됩니다 ✨',
        concept_id: concept_id,
        timestamp: Time.current.iso8601
      })
    else
      reject
    end
  end

  def unsubscribed
    concept_id = params[:concept_id]
    Rails.logger.info "User unsubscribed from concept #{concept_id} channel"
  end

  # 사용자가 현재 보고 있는 개념을 알림 (다른 사용자들에게)
  def announce_viewing
    concept_id = params[:concept_id]
    user_name = current_user&.display_name || '익명 사용자'
    
    ActionCable.server.broadcast(
      "concept_#{concept_id}",
      {
        type: 'user_viewing',
        user_name: user_name,
        user_id: current_user&.id,
        message: "#{user_name}님이 이 개념을 보고 있어요 👀",
        timestamp: Time.current.iso8601
      }
    )
  end

  # 사용자가 설명을 작성 중임을 알림
  def announce_writing_explanation
    concept_id = params[:concept_id]
    user_name = current_user&.display_name || '익명 사용자'
    
    ActionCable.server.broadcast(
      "concept_#{concept_id}",
      {
        type: 'user_writing',
        user_name: user_name,
        user_id: current_user&.id,
        message: "#{user_name}님이 새로운 설명을 작성하고 있어요 ✍️",
        timestamp: Time.current.iso8601
      }
    )
  end

  # 실시간 투표 참여 알림
  def announce_voting(data)
    concept_id = params[:concept_id]
    explanation_id = data['explanation_id']
    vote_type = data['vote_type']
    user_name = current_user&.display_name || '익명 사용자'
    
    emoji = vote_type == 'helpful' ? '👍' : '🤔'
    message = vote_type == 'helpful' ? 
              "#{user_name}님이 도움됐다고 투표했어요!" : 
              "#{user_name}님이 더 쉬운 설명이 필요하다고 했어요"
    
    ActionCable.server.broadcast(
      "concept_#{concept_id}",
      {
        type: 'live_voting',
        explanation_id: explanation_id,
        vote_type: vote_type,
        user_name: user_name,
        emoji: emoji,
        message: "#{emoji} #{message}",
        timestamp: Time.current.iso8601
      }
    )
  end

  # 실시간 질문/댓글 (향후 확장용)
  def send_question(data)
    concept_id = params[:concept_id]
    question = data['question']&.strip
    user_name = current_user&.display_name || '익명 사용자'
    
    return unless question.present? && question.length <= 200
    
    ActionCable.server.broadcast(
      "concept_#{concept_id}",
      {
        type: 'live_question',
        question: question,
        user_name: user_name,
        user_id: current_user&.id,
        message: "#{user_name}님이 질문을 올렸어요: \"#{question.truncate(50)}\"",
        timestamp: Time.current.iso8601
      }
    )
  end

  private

  def valid_concept?(concept_id)
    # UUID 형식 검증
    return false unless concept_id.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
    
    # 개념 존재 여부 확인
    Concept.exists?(concept_id)
  end
end