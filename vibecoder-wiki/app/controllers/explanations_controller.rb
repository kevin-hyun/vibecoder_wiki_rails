class ExplanationsController < ApplicationController
  before_action :set_concept
  before_action :set_explanation, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]
  before_action :check_author_or_admin, only: [:edit, :update, :destroy]
  
  def index
    @explanations = @concept.explanations
                            .includes(:author, :votes)
                            .order(vote_count: :desc, helpfulness_score: :desc)
    
    # 필터링
    if params[:difficulty].present?
      @explanations = @explanations.where(difficulty_level: params[:difficulty])
    end
    
    # 정렬
    @explanations = case params[:sort]
                   when 'newest'
                     @explanations.reorder(created_at: :desc)
                   when 'helpful'
                     @explanations.reorder(helpfulness_score: :desc, vote_count: :desc)
                   when 'clarity' 
                     @explanations.reorder(clarity_score: :desc, vote_count: :desc)
                   else
                     @explanations # 기본: vote_count desc
                   end
    
    @pagy, @explanations = pagy(@explanations, items: 10)
  end
  
  def show
    # 개별 설명 페이지 - 상세 보기용
    @related_explanations = @concept.explanations
                                   .where.not(id: @explanation.id)
                                   .order(vote_count: :desc)
                                   .limit(3)
  end
  
  def new
    @explanation = @concept.explanations.build
    
    # 비전공자를 위한 가이드 제공
    @writing_tips = [
      "일상 속 비유를 사용해주세요 (예: '냉장고처럼', '은행 업무처럼')",
      "300자 이내로 간결하게 작성해주세요",
      "전문용어 대신 쉬운 말로 설명해주세요",
      "구체적인 예시를 들어주세요"
    ]
  end
  
  def create
    @explanation = @concept.explanations.build(explanation_params)
    @explanation.author = current_user
    
    # 비전공자 친화적 초기값 설정
    @explanation.difficulty_level = determine_difficulty_level(@explanation.content)
    @explanation.tags = extract_beginner_tags(@explanation.content)
    
    if @explanation.save
      # 포인트 적립 (첫 설명 보너스)
      if current_user.explanations.count == 1
        current_user.increment!(:total_votes, 5) # 첫 설명 보너스
      end
      
      # 사용자 활동 기록
      UserActivity.create!(
        user: current_user,
        activity_type: 'explanation_created',
        target_type: 'Explanation', 
        target_id: @explanation.id,
        points_earned: 2
      )
      
      current_user.increment!(:explanations_count)
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("explanations-list", 
              partial: "explanations/explanation_card", 
              locals: { explanation: @explanation, concept: @concept }
            ),
            turbo_stream.replace("explanation-form", 
              partial: "explanations/form_success",
              locals: { message: "설명이 추가되었어요! 다른 분들이 투표해주실 거예요 ✨" }
            )
          ]
        end
        format.html { redirect_to @concept, notice: '설명을 추가해주셔서 감사해요! 다른 분들이 도움을 받을 거예요 🙏' }
      end
    else
      @writing_tips = [
        "일상 속 비유를 사용해주세요 (예: '냉장고처럼', '은행 업무처럼')",
        "300자 이내로 간결하게 작성해주세요", 
        "전문용어 대신 쉬운 말로 설명해주세요",
        "구체적인 예시를 들어주세요"
      ]
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("explanation-form",
            partial: "explanations/form",
            locals: { explanation: @explanation, concept: @concept, writing_tips: @writing_tips }
          )
        end
        format.html { render :new }
      end
    end
  end
  
  def edit
    # 수정 권한은 작성자 또는 관리자만
    @writing_tips = [
      "설명을 더 이해하기 쉽게 개선해주세요",
      "일상적인 비유나 예시를 추가해보세요",
      "어려운 용어는 더 쉬운 말로 바꿔주세요"
    ]
  end
  
  def update
    if @explanation.update(explanation_params)
      # 수정 시 난이도 재평가
      @explanation.update(
        difficulty_level: determine_difficulty_level(@explanation.content),
        tags: extract_beginner_tags(@explanation.content)
      )
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("explanation-#{@explanation.id}",
            partial: "explanations/explanation_card",
            locals: { explanation: @explanation, concept: @concept }
          )
        end
        format.html { redirect_to @concept, notice: '설명이 수정되었어요! 👍' }
      end
    else
      @writing_tips = [
        "설명을 더 이해하기 쉽게 개선해주세요",
        "일상적인 비유나 예시를 추가해보세요", 
        "어려운 용어는 더 쉬운 말로 바꿔주세요"
      ]
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("explanation-edit-form",
            partial: "explanations/edit_form",
            locals: { explanation: @explanation, concept: @concept, writing_tips: @writing_tips }
          )
        end
        format.html { render :edit }
      end
    end
  end
  
  def destroy
    @explanation.destroy
    current_user.decrement!(:explanations_count)
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("explanation-#{@explanation.id}")
      end
      format.html { redirect_to @concept, notice: '설명이 삭제되었어요' }
    end
  end
  
  # 투표 기능 - 비전공자 친화적
  def vote
    @explanation = Explanation.find(params[:id])
    vote_type = params[:vote_type] # 'helpful' or 'difficult'
    
    # IP 기반 중복 투표 방지 (로그인/비로그인 모두)
    user_identifier = user_signed_in? ? current_user.id : request.remote_ip
    existing_vote = @explanation.votes.find_by(
      user_signed_in? ? { user_id: current_user.id } : { ip_address: request.remote_ip }
    )
    
    if existing_vote
      if existing_vote.vote_type == vote_type
        # 같은 투표 취소
        existing_vote.destroy
        action_message = vote_type == 'helpful' ? '도움됨 투표를 취소했어요' : '어려움 투표를 취소했어요'
      else
        # 투표 변경
        existing_vote.update!(vote_type: vote_type)
        action_message = vote_type == 'helpful' ? '도움된다고 바꿨어요!' : '어렵다고 바꿨어요'
      end
    else
      # 새 투표 생성
      vote_params = {
        explanation: @explanation,
        vote_type: vote_type,
        reason: params[:reason]
      }
      
      if user_signed_in?
        vote_params[:user] = current_user
      else
        vote_params[:ip_address] = request.remote_ip
      end
      
      Vote.create!(vote_params)
      action_message = vote_type == 'helpful' ? '도움됐어요! 감사해요 👍' : '좀 더 쉽게 설명해주시면 좋겠어요'
      
      # 첫 투표 시 포인트 (로그인 사용자만)
      if user_signed_in? && current_user.votes.count == 1
        current_user.increment!(:total_votes, 3) # 첫 투표 보너스
      end
    end
    
    # 투표 수 다시 계산
    @explanation.update_vote_counts!
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("explanation-votes-#{@explanation.id}",
            partial: "explanations/vote_buttons",
            locals: { explanation: @explanation, concept: @concept }
          ),
          turbo_stream.replace("vote-message",
            partial: "shared/flash_message", 
            locals: { message: action_message, type: 'success' }
          )
        ]
      end
      format.html { redirect_to @concept, notice: action_message }
    end
  end
  
  # 베스트 설명으로 선정 (관리자 전용)
  def make_best
    @explanation = Explanation.find(params[:id])
    
    unless current_user&.admin?
      redirect_to @concept, alert: '관리자만 베스트 설명을 선정할 수 있어요'
      return
    end
    
    # 기존 베스트 설명 해제
    @concept.explanations.update_all(is_best_explanation: false)
    
    # 새로운 베스트 설명 설정
    @explanation.update!(is_best_explanation: true)
    
    # 작성자에게 보너스 포인트
    @explanation.author.increment!(:total_votes, 10)
    
    UserActivity.create!(
      user: @explanation.author,
      activity_type: 'best_explanation_selected',
      target_type: 'Explanation',
      target_id: @explanation.id,
      points_earned: 10
    )
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("explanations-list",
          partial: "concepts/explanations_section",
          locals: { concept: @concept }
        )
      end
      format.html { redirect_to @concept, notice: '베스트 설명으로 선정되었어요! ⭐' }
    end
  end
  
  private
  
  def set_concept
    @concept = Concept.friendly.find(params[:concept_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to concepts_path, alert: '요청하신 개념을 찾을 수 없어요'
  end
  
  def set_explanation
    @explanation = @concept.explanations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to @concept, alert: '요청하신 설명을 찾을 수 없어요'
  end
  
  def check_author_or_admin
    unless @explanation.author == current_user || current_user&.admin?
      redirect_to @concept, alert: '본인이 작성한 설명만 수정하거나 삭제할 수 있어요'
    end
  end
  
  def explanation_params
    params.require(:explanation).permit(
      :content, :simple_analogy, :example, :difficulty_level, :reason,
      tags: []
    )
  end
  
  # 비전공자를 위한 난이도 자동 판별
  def determine_difficulty_level(content)
    return 'beginner' unless content.present?
    
    # 어려운 용어들 (비전공자 기준)
    advanced_terms = ['API', 'HTTP', '서버', '클라이언트', '데이터베이스', '프레임워크', 
                     '라이브러리', '알고리즘', '스키마', '쿼리', '메소드', '인스턴스']
    intermediate_terms = ['웹사이트', '앱', '소프트웨어', '프로그램', '코드', '버그']
    
    content_downcase = content.downcase
    
    advanced_count = advanced_terms.count { |term| content_downcase.include?(term.downcase) }
    intermediate_count = intermediate_terms.count { |term| content_downcase.include?(term.downcase) }
    
    if advanced_count >= 2
      'advanced'
    elsif intermediate_count >= 1 || advanced_count >= 1
      'intermediate' 
    else
      'beginner'
    end
  end
  
  # 비전공자 친화적 태그 자동 추출
  def extract_beginner_tags(content)
    return [] unless content.present?
    
    tags = []
    
    # 일상 비유 감지
    if content.match?(/같은|마치|비슷|처럼|예를 들어/)
      tags << '일상비유'
    end
    
    # 예시 포함 감지  
    if content.match?(/예시|예를 들면|가령/)
      tags << '예시포함'
    end
    
    # 초보자 추천 감지
    if content.length <= 200 && !content.match?(/API|HTTP|서버|클라이언트/i)
      tags << '초보추천'
    end
    
    # 실무 관련 감지
    if content.match?(/실제로|현실에서|업무에서|실무/)
      tags << '실무연관'
    end
    
    tags
  end
end