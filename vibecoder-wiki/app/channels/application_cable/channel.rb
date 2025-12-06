module ApplicationCable
  class Channel < ActionCable::Channel::Base
    private

    def current_user
      connection.current_user
    end

    def current_user_or_guest
      current_user || Guest.new(request.remote_ip)
    end
  end
end