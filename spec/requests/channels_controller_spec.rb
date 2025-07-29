# frozen_string_literal: true

RSpec.describe Chat::Api::ChannelsController do
  before do
    SiteSetting.chat_enabled = true
    SiteSetting.chat_allowed_groups = Group::AUTO_GROUPS[:everyone]
  end

  describe "#create" do
    fab!(:admin)
    fab!(:moderator)
    fab!(:public_category) { Fabricate(:category, name: "Public Category") }
    fab!(:dummy_private_category) { Fabricate(:category, name: "Dummy Private Category") }

    let(:public_params) do
      {
        channel: {
          type: public_category.class.name,
          chatable_id: public_category.id,
          name: "channel name",
          slug: "channel-name",
          description: "My new channel",
          threading_enabled: true,
        },
      }
    end

    let(:private_params) do
      {
        channel: {
          type: dummy_private_category.class.name,
          chatable_id: dummy_private_category.id,
          name: "whatsup",
          slug: "whatsup",
          description: "My new private channel",
          threading_enabled: true,
        },
      }
    end

    let(:private_params_with_spaces) do
      {
        channel: {
          type: dummy_private_category.class.name,
          chatable_id: dummy_private_category.id,
          name: "whats up there",
          slug: "whats-up-there",
          description: "My new private channel that has spaces",
          threading_enabled: true,
        },
      }
    end

    before do
      SiteSetting.x_chat_customisations_private_chat_dummy_category_id = dummy_private_category.id
      sign_in(admin)
    end

    it "creates a public channel associated to a category" do
      post "/chat/api/channels", params: public_params
      expect(response.status).to eq(200)

      new_channel = Chat::Channel.find(response.parsed_body.dig("channel", "id"))

      expect(new_channel.name).to eq(public_params[:channel][:name])
      expect(new_channel.slug).to eq("channel-name")
      expect(new_channel.description).to eq(public_params[:channel][:description])
      expect(new_channel.chatable_type).to eq(public_category.class.name)
      expect(new_channel.chatable_id).to eq(public_category.id)
    end

    it "creates a private channel associated to a new category and group, which are removed along with the channel on delete" do
      post "/chat/api/channels", params: private_params
      expect(response.status).to eq(200)

      expect(Category.find_by(name: private_params[:channel][:name])).to be_present
      expect(Category.find_by(name: private_params[:channel][:name]).read_restricted).to eq(true)
      expect(Group.find_by(name: private_params[:channel][:name])).to be_present

      new_channel = Chat::Channel.find(response.parsed_body.dig("channel", "id"))

      expect(new_channel.name).to eq(private_params[:channel][:name])
      expect(new_channel.slug).to eq("whatsup")
      expect(new_channel.description).to eq(private_params[:channel][:description])
      expect(new_channel.chatable_type).to eq(dummy_private_category.class.name)
      expect(new_channel.chatable_id).to eq(Category.find_by(name: private_params[:channel][:name]).id)

      delete "/chat/api/channels/#{new_channel.id}"
      expect(response.status).to eq(200)
      expect(job_enqueued?(job: Jobs::Chat::ChannelDelete, args: { chat_channel_id: new_channel.id, channel_name: new_channel.name }),).to eq(true)
      Jobs::Chat::ChannelDelete.new.execute(chat_channel_id: new_channel.id, channel_name: new_channel.name)

      expect(Category.find_by(name: private_params[:channel][:name])).not_to be_present
      expect(Group.find_by(name: private_params[:channel][:name])).not_to be_present
      expect(Chat::Channel.find_by(id: new_channel.id)).not_to be_present
    end

    it "creates a private channel associated to a new category and group, even with spaces in the name, which are removed along with the channel on delete" do
      post "/chat/api/channels", params: private_params_with_spaces
      expect(response.status).to eq(200)

      expect(Category.find_by(name: private_params_with_spaces[:channel][:name])).to be_present
      expect(Category.find_by(name: private_params_with_spaces[:channel][:name]).read_restricted).to eq(true)
      expected_group_name = private_params_with_spaces[:channel][:name].parameterize(separator: '_')
      expect(Group.find_by(name: expected_group_name)).to be_present

      new_channel = Chat::Channel.find(response.parsed_body.dig("channel", "id"))

      expect(new_channel.name).to eq(private_params_with_spaces[:channel][:name])
      expect(new_channel.slug).to eq("whats-up-there")
      expect(new_channel.description).to eq(private_params_with_spaces[:channel][:description])
      expect(new_channel.chatable_type).to eq(dummy_private_category.class.name)
      expect(new_channel.chatable_id).to eq(Category.find_by(name: private_params_with_spaces[:channel][:name]).id)

      delete "/chat/api/channels/#{new_channel.id}"
      expect(response.status).to eq(200)
      expect(job_enqueued?(job: Jobs::Chat::ChannelDelete, args: { chat_channel_id: new_channel.id, channel_name: new_channel.name }),).to eq(true)
      Jobs::Chat::ChannelDelete.new.execute(chat_channel_id: new_channel.id, channel_name: new_channel.name)

      expect(Category.find_by(name: private_params_with_spaces[:channel][:name])).not_to be_present
      expect(Group.find_by(name: private_params_with_spaces[:channel][:name])).not_to be_present
      expect(Chat::Channel.find_by(id: new_channel.id)).not_to be_present
    end
  end
end
