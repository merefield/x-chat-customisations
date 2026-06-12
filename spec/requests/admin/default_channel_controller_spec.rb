# frozen_string_literal: true

RSpec.describe ChatCustomisations::Admin::DefaultChannelController do
  fab!(:admin)
  fab!(:user)
  fab!(:public_category) { Fabricate(:category, name: "Public") }
  fab!(:private_category) do
    Fabricate(:private_category, group: Fabricate(:group), name: "Private")
  end
  fab!(:public_channel) { Fabricate(:category_channel, chatable: public_category) }
  fab!(:private_channel) { Fabricate(:category_channel, chatable: private_category) }

  before do
    SiteSetting.chat_enabled = true
    SiteSetting.chat_allowed_groups = Group::AUTO_GROUPS[:everyone]
  end

  describe "#show" do
    it "routes the Chat default channel tab to the admin app shell" do
      expect(get: "/admin/plugins/chat/default-channel").to route_to(
        controller: "admin/plugins",
        action: "index",
      )
    end

    it "lists public category channels for admins" do
      sign_in(admin)

      get "/admin/plugins/x-chat-customisations/default-channel.json"

      expect(response.status).to eq(200)
      expect(
        response.parsed_body["chat_channels"].map { |channel| channel["id"] },
      ).to contain_exactly(public_channel.id)
    end

    it "requires an admin" do
      sign_in(user)

      get "/admin/plugins/x-chat-customisations/default-channel.json"

      expect(response.status).to eq(404)
    end
  end

  describe "#update" do
    it "sets the default chat channel" do
      sign_in(admin)

      put "/admin/plugins/x-chat-customisations/default-channel.json",
          params: {
            chat_channel_id: public_channel.id,
          }

      expect(response.status).to eq(200)
      expect(response.parsed_body["default_chat_channel_id"]).to eq(public_channel.id)
      expect(SiteSetting.x_chat_customisations_default_chat_channel_id).to eq(public_channel.id)
    end

    it "clears the default chat channel" do
      SiteSetting.x_chat_customisations_default_chat_channel_id = public_channel.id
      sign_in(admin)

      put "/admin/plugins/x-chat-customisations/default-channel.json",
          params: {
            chat_channel_id: 0,
          }

      expect(response.status).to eq(200)
      expect(SiteSetting.x_chat_customisations_default_chat_channel_id).to eq(0)
    end

    it "rejects private category-backed channels" do
      sign_in(admin)

      put "/admin/plugins/x-chat-customisations/default-channel.json",
          params: {
            chat_channel_id: private_channel.id,
          }

      expect(response.status).to eq(404)
      expect(SiteSetting.x_chat_customisations_default_chat_channel_id).to eq(0)
    end
  end
end
