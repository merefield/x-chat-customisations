# frozen_string_literal: true

class Chat::Api::ChannelsMembershipsByUsernameController < Chat::ApiController
  def destroy
    ensure_staff

    channel_id = params.fetch(:channel_id) { request.path_parameters[:channel_id] }
    username = params.fetch(:username) { request.path_parameters[:username] }

    raise ActionController::ParameterMissing, :channel_id if channel_id.blank?
    raise ActionController::ParameterMissing, :username if username.blank?

    user = User.find_by(username_lower: username.downcase)
    channel = Chat::Channel.find_by(id: channel_id)

    raise Discourse::NotFound if channel.blank? || user.blank?

    channel.leave(user)

    if channel.chatable.is_a?(Category) && channel.chatable.read_restricted
      category_group = CategoryGroup.find_by(category_id: channel.chatable.id)
      category_group&.group&.users&.destroy(user)
    end

    head :no_content
  end

  private

  def ensure_staff
    raise Discourse::InvalidAccess.new unless current_user&.staff?
  end
end
