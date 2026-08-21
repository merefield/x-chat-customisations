# frozen_string_literal: true

RSpec.describe Chat::Api::ChannelsPostingModeController do
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
    it "allows staff to set the posting mode on category channels" do
      sign_in(admin)

      put "/chat/api/channels/#{channel.id}/posting-mode",
          params: {
            posting_mode: "staff_only_replies_allowed",
          }

      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("channel", "x_chat_posting_mode")).to eq(
        "staff_only_replies_allowed",
      )
      expect(channel.reload.x_chat_posting_mode).to eq("staff_only_replies_allowed")
    end

    it "does not allow regular users to set the posting mode" do
      sign_in(user)

      put "/chat/api/channels/#{channel.id}/posting-mode", params: { posting_mode: "staff_only" }

      expect(response.status).to eq(403)
      expect(channel.reload.x_chat_posting_mode).to eq("anyone")
    end

    it "does not allow posting modes on direct message channels" do
      direct_message_channel = Fabricate(:direct_message_channel, users: [admin, user])

      sign_in(admin)

      put "/chat/api/channels/#{direct_message_channel.id}/posting-mode",
          params: {
            posting_mode: "staff_only",
          }

      expect(response.status).to eq(403)
      expect(direct_message_channel.reload.x_chat_posting_mode).to eq("anyone")
    end
  end
end
