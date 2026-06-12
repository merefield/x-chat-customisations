# frozen_string_literal: true

RSpec.describe Chat::Api::ChannelsSilentMemberAddsController do
  fab!(:admin)
  fab!(:user)
  fab!(:channel, :chat_channel)

  before do
    SiteSetting.chat_enabled = true
    SiteSetting.chat_allowed_groups = Group::AUTO_GROUPS[:everyone]
    channel.add(user)
    channel.add(admin)
  end

  describe "#update" do
    it "allows staff to enable silent member adds on category channels" do
      sign_in(admin)

      put "/chat/api/channels/#{channel.id}/silent-member-adds", params: { enabled: true }

      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("channel", "x_chat_silent_member_adds")).to eq(true)
      expect(channel.reload.x_chat_silent_member_adds).to eq(true)
    end

    it "allows staff to disable silent member adds on category channels" do
      channel.x_chat_silent_member_adds = true
      sign_in(admin)

      put "/chat/api/channels/#{channel.id}/silent-member-adds", params: { enabled: false }

      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("channel", "x_chat_silent_member_adds")).to eq(false)
      expect(channel.reload.x_chat_silent_member_adds).to eq(false)
    end

    it "does not allow regular users to update silent member adds" do
      sign_in(user)

      put "/chat/api/channels/#{channel.id}/silent-member-adds", params: { enabled: true }

      expect(response.status).to eq(403)
      expect(channel.reload.x_chat_silent_member_adds).to eq(false)
    end

    it "does not allow silent member adds on direct message channels" do
      direct_message_channel = Fabricate(:direct_message_channel, users: [admin, user])

      sign_in(admin)

      put "/chat/api/channels/#{direct_message_channel.id}/silent-member-adds",
          params: {
            enabled: true,
          }

      expect(response.status).to eq(403)
      expect(direct_message_channel.reload.x_chat_silent_member_adds).to eq(false)
    end
  end
end
