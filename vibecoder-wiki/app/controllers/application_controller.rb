class ApplicationController < ActionController::Base
  include Pagy::Backend
  
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :track_page_view
  before_action :check_premium_expiration, if: :user_signed_in?
  before_action :set_beginner_friendly_meta
  
  protect_from_forgery with: :exception
  
  helper_method :current_user_or_guest, :beginner_signed_in?, :premium_member?
  
  protected
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:display_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :display_name, :photo_url, :theme, :email_notifications
    ])
  end
  
  def require_admin!
    redirect_to root_path, alert: '관리자 권한이 필요해요 🔒' unless current_user&.admin?
  end
  
  def current_user_or_guest
    current_user || Guest.new(request.remote_ip)
  end
  
  def track_page_view
    return unless params[:controller] == 'concepts' && params[:action] == 'show'
    return unless @concept
    
    # 같은 사용자의 1시간 내 중복 조회 방지
    recent_view = @concept.concept_views.where(
      user: current_user,
      ip_address: request.remote_ip,
      created_at: 1.hour.ago..Time.current
    ).exists?
    
    return if recent_view
    
    @concept.increment!(:view_count)
    @concept.concept_views.create!(
      user: current_user,
      ip_address: request.remote_ip,
      viewed_at: Time.current
    )
  end
  
  def check_premium_expiration
    return unless current_user.is_premium && current_user.premium_expires_at
    
    if current_user.premium_expires_at.past?
      current_user.update!(is_premium: false, premium_expires_at: nil)
      flash[:notice] = '바이브 마스터(프리미엄) 멤버십이 만료되었어요. 계속 이용하시려면 갱신해주세요.'
    elsif current_user.premium_expires_at < 7.days.from_now
      days_left = (current_user.premium_expires_at.to_date - Date.current).to_i
      flash[:warning] = "바이브 마스터 멤버십이 #{days_left}일 후 만료됩니다."
    end
  end
  
  def set_beginner_friendly_meta
    @wiki_title = '바이브코더 위키 - 비전공자를 위한 쉬운 IT 개념 설명'
    @wiki_description = '30-40대 창업가와 비전공자가 IT 개념을 가장 쉽게 이해할 수 있는 커뮤니티 위키입니다'
    @wiki_keywords = 'IT 기초, 비전공자, 쉬운 설명, 창업, 개발 입문, 바이브 코딩'
  end
  
  def beginner_signed_in?
    user_signed_in? && current_user.role != 'guest'
  end
  
  def premium_member?
    user_signed_in? && current_user.premium_active?
  end
  
  def provide_beginner_guidance(message_type)
    guidance_messages = {
      first_visit: "바이브코더 위키에 오신 걸 환영해요! IT 개념들을 쉬운 언어로 설명해드릴게요.",
      first_explanation: "첫 설명 작성을 준비 중이시군요! 일상 비유를 사용하면 다른 분들이 더 쉽게 이해할 수 있어요.",
      first_vote: "좋은 설명에 투표해주세요! 여러분의 투표가 더 나은 설명을 찾는 데 도움이 됩니다.",
      premium_consideration: "바이브 마스터가 되시면 더 많은 기능을 이용하실 수 있어요!"
    }
    
    guidance_messages[message_type] || "바이브코더 위키와 함께 IT 세상을 탐험해보세요!"
  end
  
  helper_method :provide_beginner_guidance
end

# Guest class for non-logged-in users
class Guest
  attr_reader :ip_address
  
  def initialize(ip_address)
    @ip_address = ip_address
  end
  
  def display_name
    "게스트"
  end
  
  def admin?
    false
  end
  
  def premium_active?
    false
  end
  
  def can_vote?
    true # 비로그인 사용자도 IP 기반으로 투표 가능
  end
end