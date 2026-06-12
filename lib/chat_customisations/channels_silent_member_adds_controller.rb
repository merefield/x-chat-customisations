# frozen_string_literal: true

class Chat::Api::ChannelsSilentMemberAddsController < Chat::ApiController
  def update
    ensure_staff

    channel = Chat::Channel.find(params.require(:channel_id))
    raise Discourse::InvalidAccess if !channel.category_channel?
    raise Discourse::InvalidAccess if !guardian.can_edit_chat_channel?(channel)

    channel.x_chat_silent_member_adds = ActiveModel::Type::Boolean.new.cast(params[:enabled])

    render_serialized(
      channel,
      Chat::ChannelSerializer,
      root: "channel",
      membership: channel.membership_for(current_user),
    )
  end

  private

  def ensure_staff
    raise Discourse::InvalidAccess if !current_user&.staff?
  end
end
