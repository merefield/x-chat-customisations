module ChatCustomisations
  module ApiChannelsMembershipsControllerExtension
    def destroy
      ensure_staff

      params.require(:channel_id)
      params.require(:username)
          
      user = User.find_by(username_lower: params[:username].downcase)
      channel = Chat::Channel.find_by(id: params[:channel_id])

      if user && channel
        channel.leave(user)

        if channel.chatable.is_a?(Category) && channel.chatable.read_restricted
          cg = CategoryGroup.find_by(category_id: channel.chatable.id)

          if cg&.group
            group = cg.group

            if group.users.exists?(user.id)
              group.users.destroy(user)  # safely removes the association
            end
          end
        end
      end
    end

    def ensure_staff
      raise Discourse::InvalidAccess.new unless current_user && current_user.staff?
    end
  end
end