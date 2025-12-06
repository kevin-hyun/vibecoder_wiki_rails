class ConceptsController < ApplicationController
  before_action :set_concept, only: [:show, :edit, :update, :destroy, :verify, :bookmark]
  before_action :require_admin!, only: [:new, :create, :edit, :update, :destroy, :verify]
  
  def index
    @concepts = Concept.includes(:concept_tags, :creator)
    
    # 카테고리 필터
    if params[:category].present?
      @concepts = @concepts.where(category: params[:category])
    end
    
    # 레벨 필터  
    if params[:level].present?
      @concepts = @concepts.where(level: params[:level])
    end
    
    # 정렬
    @concepts = case params[:sort]
                when 'popular'
                  @concepts.order(view_count: :desc)
                when 'beginner'
                  @concepts.where(level: 1).order(created_at: :desc)
                when 'verified'
                  @concepts.where(is_verified: true).order(average_rating: :desc)
                else
                  @concepts.order(created_at: :desc)
                end
    
    @pagy, @concepts = pagy(@concepts, items: 12)
    
    # Turbo Frame request for infinite scroll
    if params[:page].present? && request.headers['Turbo-Frame'].present?
      render partial: 'concepts/cards', locals: { concepts: @concepts }
      return
    end
  end
  
  def show
    @concept = Concept.includes(:explanations, :concept_tags).friendly.find(params[:id])
    
    # 베스트 설명 3개 (캐러셀용) - vote_count 기준 정렬
    @best_explanations = @concept.explanations
                                 .includes(:author, :votes)
                                 .order(vote_count: :desc, helpfulness_score: :desc)
                                 .limit(3)
    
    # 모든 설명 (투표순)
    @all_explanations = @concept.explanations
                                .includes(:author, :votes)
                                .order(vote_count: :desc, helpfulness_score: :desc)
    
    @new_explanation = @concept.explanations.build if user_signed_in?
    
    # 관련 개념 (같은 카테고리, 비슷한 레벨)
    @related_concepts = Concept.where(category: @concept.category)
                               .where.not(id: @concept.id)
                               .where(level: [@concept.level - 1, @concept.level, @concept.level + 1].compact)
                               .order(view_count: :desc)
                               .limit(4)
  end
  
  def search
    @query = params[:q]&.strip
    
    if @query.present?
      # 간단한 LIKE 검색 (SQLite 호환)
      @concepts = Concept.where('title LIKE ? OR description LIKE ? OR simple_definition LIKE ?', 
                               "%#{@query}%", "%#{@query}%", "%#{@query}%")
                        .includes(:concept_tags, :creator)
                        .order(view_count: :desc)
                        .limit(20)
      
      respond_to do |format|
        format.html
        format.json { 
          render json: @concepts.map { |c| { 
            id: c.id, 
            title: c.title, 
            category: c.category,
            level: c.level,
            simple_definition: c.simple_definition,
            url: concept_path(c) 
          }}
        }
      end
    else
      @concepts = []
    end
  end
  
  def suggestions
    @term = params[:term]&.strip
    return render json: [] unless @term.present?
    
    @suggestions = Concept.where('title LIKE ?', "#{@term}%")
                          .order(view_count: :desc)
                          .pluck(:title)
                          .first(8)
    
    render json: @suggestions
  end
  
  def popular
    @concepts = Concept.where(is_popular: true)
                       .includes(:concept_tags)
                       .order(view_count: :desc)
                       .limit(6)
    
    render partial: 'concepts/popular_grid', locals: { concepts: @concepts }
  end
  
  def beginner
    @concepts = Concept.where(level: 1)
                       .where(is_verified: true)
                       .includes(:concept_tags)
                       .order(average_rating: :desc, view_count: :desc)
                       .limit(10)
    
    render partial: 'concepts/beginner_list', locals: { concepts: @concepts }
  end
  
  def verify
    @concept.update!(is_verified: true)
    
    # 관리자 활동 로그
    UserActivity.create!(
      user: current_user,
      activity_type: 'concept_verified',
      target_type: 'Concept',
      target_id: @concept.id,
      points_earned: 0
    )
    
    redirect_to @concept, notice: '개념이 검증되었어요! ✅'
  end
  
  def bookmark
    if user_signed_in?
      bookmark = current_user.bookmarks.find_by(concept: @concept)
      
      if bookmark
        bookmark.destroy
        action = '북마크를 해제했어요'
        bookmarked = false
      else
        current_user.bookmarks.create!(concept: @concept)
        action = '북마크에 추가했어요'
        bookmarked = true
      end
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "bookmark-button-#{@concept.id}",
            partial: 'concepts/bookmark_button',
            locals: { concept: @concept, bookmarked: bookmarked }
          )
        end
        format.html { redirect_to @concept, notice: "#{action} 📚" }
      end
    else
      redirect_to new_user_session_path, alert: '북마크하려면 로그인이 필요해요 📚'
    end
  end
  
  # Admin actions
  def new
    @concept = Concept.new
  end
  
  def create
    @concept = Concept.new(concept_params)
    @concept.created_by = current_user.id
    
    if @concept.save
      # 태그 처리
      if params[:concept][:tag_list].present?
        create_concept_tags(@concept, params[:concept][:tag_list])
      end
      
      current_user.increment!(:concepts_contributed)
      redirect_to @concept, notice: '개념이 생성되었어요! 🎉'
    else
      render :new
    end
  end
  
  def edit
    # Admin only - already protected by before_action
  end
  
  def update
    if @concept.update(concept_params)
      # 태그 업데이트
      if params[:concept][:tag_list].present?
        @concept.concept_tags.destroy_all
        create_concept_tags(@concept, params[:concept][:tag_list])
      end
      
      redirect_to @concept, notice: '개념이 수정되었어요! ✏️'
    else
      render :edit
    end
  end
  
  def destroy
    @concept.destroy
    current_user.decrement!(:concepts_contributed)
    redirect_to concepts_path, notice: '개념이 삭제되었어요 🗑️'
  end
  
  private
  
  def set_concept
    @concept = Concept.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to concepts_path, alert: '요청하신 IT 개념을 찾을 수 없어요. 다른 개념들을 둘러보시는 건 어떨까요?'
  end
  
  def concept_params
    params.require(:concept).permit(
      :title, :simple_definition, :description, 
      :category, :level, :why_important, :is_popular
    )
  end
  
  def create_concept_tags(concept, tag_list)
    return unless tag_list.is_a?(Array)
    
    tag_list.reject(&:blank?).each do |tag_name|
      concept.concept_tags.create!(
        id: SecureRandom.uuid,
        tag: tag_name.strip.downcase
      )
    end
  end
end