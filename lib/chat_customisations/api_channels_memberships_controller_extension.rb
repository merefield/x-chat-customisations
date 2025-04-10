# frozen_string_literal: true
module ChatCustomisations
  module ApiChannelsMembershipsControllerExtension
    def destroy
      ensure_staff

      channel_id = params.fetch(:channel_id) { request.path_parameters[:channel_id] }
      username = params.fetch(:username) { request.path_parameters[:username] }

      raise ActionController::ParameterMissing, :channel_id if channel_id.blank?
      raise ActionController::ParameterMissing, :username if username.blank?

      user = User.find_by(username_lower: username.downcase)
      channel = Chat::Channel.find_by(id: channel_id)

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
