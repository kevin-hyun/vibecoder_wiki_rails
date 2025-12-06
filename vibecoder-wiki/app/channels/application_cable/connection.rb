module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      logger.info "ActionCable connected: #{current_user&.display_name || 'anonymous'}"
    end

    private

    def find_verified_user
      # Devise 세션에서 사용자 확인
      if verified_user = User.find_by(id: cookies.encrypted[:user_id])
        verified_user
      else
        # 익명 사용자도 허용 (IP 기반 식별)
        nil
      end
    end
  end
end