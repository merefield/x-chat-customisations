# frozen_string_literal: true

RSpec.describe Chat::Api::ChannelMessagesController do
  fab!(:admin)
  fab!(:moderator)
  fab!(:user)
  fab!(:channel, :chat_channel) { Fabricate(:chat_channel, threading_enabled: true) }
  fab!(:direct_message_channel) { Fabricate(:direct_message_channel, users: [user, admin]) }
  fab!(:original_message) { Fabricate(:chat_message, chat_channel: channel, user: admin) }

  before do
    SiteSetting.chat_enabled = true
    SiteSetting.chat_allowed_groups = Group::AUTO_GROUPS[:everyone]
    channel.add(user)
    channel.add(admin)
    channel.add(moderator)
  end

  it "allows anyone to post by default" do
    sign_in(user)

    expect { create_message(channel, "hello") }.to change {
      Chat::Message.where(chat_channel: channel, user: user).count
    }.by(1)

    expect(response.status).to eq(200)
  end

  it "only allows staff to post when the posting mode is staff only" do
    channel.x_chat_posting_mode = "staff_only"

    sign_in(user)
    expect { create_message(channel, "blocked") }.not_to change { Chat::Message.count }
    expect(response.status).to eq(422)
    expect(response.parsed_body["errors"].join).to include(
      I18n.t("x_chat_customisations.posting_modes.staff_only"),
    )

    sign_in(moderator)
    expect { create_message(channel, "allowed") }.to change {
      Chat::Message.where(chat_channel: channel, user: moderator).count
    }.by(1)
  end

  it "allows regular users to reply but not post when replies are allowed" do
    channel.x_chat_posting_mode = "staff_only_replies_allowed"

    sign_in(user)
    expect { create_message(channel, "blocked") }.not_to change { Chat::Message.count }
    expect(response.status).to eq(422)
    expect(response.parsed_body["errors"].join).to include(
      I18n.t("x_chat_customisations.posting_modes.staff_only_replies_allowed"),
    )

    expect { create_message(channel, "reply", in_reply_to_id: original_message.id) }.to change {
      Chat::Message.where(chat_channel: channel, user: user).count
    }.by(1)

    expect(response.status).to eq(200)
  end

  it "does not apply posting modes to direct messages" do
    direct_message_channel.x_chat_posting_mode = "staff_only"
    direct_message_channel.add(user)

    sign_in(user)

    expect { create_message(direct_message_channel, "dm") }.to change {
      Chat::Message.where(chat_channel: direct_message_channel, user: user).count
    }.by(1)

    expect(response.status).to eq(200)
  end

  private

  def create_message(channel, message, extra_params = {})
    post "/chat/#{channel.id}.json", params: { message: message }.merge(extra_params)
  end
end
