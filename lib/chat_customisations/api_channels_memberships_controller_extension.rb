module ChatCustomisations
  module ApiChannelsMembershipsControllerExtension
    def destroy
      ensure_staff

      params.require(:channel_id)
      params.require(:username)
          
      user = User.find_by(username_lower: params[:username].downcase)
      channel = Chat::Channel.find_by(id: params[:channel_id])

      channel.leave(user) if user && channel
    end

    def ensure_staff
      raise Discourse::InvalidAccess.new unless current_user && current_user.staff?
    end
  end
end