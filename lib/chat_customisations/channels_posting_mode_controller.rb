# frozen_string_literal: true

class Chat::Api::ChannelsPostingModeController < Chat::ApiController
  def update
    ensure_staff

    channel = Chat::Channel.find(params.require(:channel_id))
    raise Discourse::InvalidAccess if !channel.category_channel?
    raise Discourse::InvalidAccess if !guardian.can_edit_chat_channel?(channel)

    posting_mode = params.require(:posting_mode)
    raise Discourse::InvalidParameters.new(:posting_mode) if !valid_posting_mode?(posting_mode)

    channel.x_chat_posting_mode = posting_mode

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

  def valid_posting_mode?(posting_mode)
    ChatCustomisations::ChannelPostingMode::MODES.include?(posting_mode)
  end
end
