# frozen_string_literal: true

RSpec.describe Chat::Api::ChannelsMembershipsController do
  fab!(:admin)
  fab!(:moderator)
  fab!(:other_user) { Fabricate(:user) }
  fab!(:third_user) { Fabricate(:user) }
  fab!(:public_category) { Fabricate(:category, name: "Public Category") }
  fab!(:private_group) { Fabricate(:group, name: "whatsup") }
  fab!(:private_category) { Fabricate(:category, name: "whatsup", read_restricted: true) }
  fab!(:category_group) do
    Fabricate(:category_group, category: private_category, group: private_group)
  end
  fab!(:public_channel) do
    Fabricate(:category_channel)
  end
  fab!(:private_channel) do
    Fabricate(:private_category_channel, group: private_group)
  end

  before do
    SiteSetting.chat_enabled = true
    SiteSetting.chat_allowed_groups = Group::AUTO_GROUPS[:everyone]
    private_channel.chatable_id = private_category.id
    sign_in(admin)
  end

  describe "#create" do
    describe "success" do
      it "works for public channel" do
        post "/chat/api/channels/#{public_channel.id}/memberships",
             params: {
               usernames: [other_user.username],
             }

        expect(response.status).to eq(200)

        expect(Chat::UserChatChannelMembership.find_by(chat_channel_id: public_channel.id, following: true, user_id: other_user.id)).to be_present
      end

      it "works for private channel" do
        expect(GroupUser.where(group_id: CategoryGroup.find_by(category_id: private_channel.chatable.id).group_id).count).to eq(0)

        post "/chat/api/channels/#{private_channel.id}/memberships",
              params: {
                usernames: [other_user.username],
              }

        expect(response.status).to eq(200)
        expect(GroupUser.where(group_id: CategoryGroup.find_by(category_id: private_channel.chatable.id).group_id).count).to eq(1)
        expect(Chat::UserChatChannelMembership.find_by(chat_channel_id: private_channel.id, following: true, user_id: other_user.id)).to be_present
        expect(GroupUser.find_by(group_id: Group.find_by(name: "whatsup").id, user_id: other_user.id)).to be_present
      end

      it "works for private channel even when you try to add same person again" do
        expect(GroupUser.where(group_id: CategoryGroup.find_by(category_id: private_channel.chatable.id).group_id).count).to eq(0)

        post "/chat/api/channels/#{private_channel.id}/memberships",
              params: {
                usernames: [other_user.username, third_user.username],
              }

        expect(response.status).to eq(200)

        post "/chat/api/channels/#{private_channel.id}/memberships",
              params: {
                usernames: [third_user.username],
              }

        expect(response.status).to eq(200)

        expect(GroupUser.where(group_id: CategoryGroup.find_by(category_id: private_channel.chatable.id).group_id).count).to eq(2)
        expect(Chat::UserChatChannelMembership.find_by(chat_channel_id: private_channel.id, following: true, user_id: other_user.id)).to be_present
        expect(GroupUser.find_by(group_id: Group.find_by(name: "whatsup").id, user_id: other_user.id)).to be_present
      end

      it "succeeds if the user is moderator" do
        sign_in(moderator)
        post "/chat/api/channels/#{public_channel.id}/memberships",
              params: {
                usernames: [other_user.username],
              }

        expect(response.status).to eq(200)
      end
    end
  end

  describe "failure" do
    it "fails if the user is not staff" do
      sign_in(third_user)
      post "/chat/api/channels/#{public_channel.id}/memberships",
            params: {
              usernames: [other_user.username],
            }

      expect(response.status).to eq(422)
    end
  end

  describe "#destroy" do
    describe "success" do
      before do
        sign_in(admin)
        SiteSetting.chat_enabled = true
        SiteSetting.chat_allowed_groups = Group::AUTO_GROUPS[:everyone]
        private_channel.chatable_id = private_category.id
        post "/chat/api/channels/#{public_channel.id}/memberships",
        params: {
          usernames: [other_user.username],
        }
        post "/chat/api/channels/#{private_channel.id}/memberships",
        params: {
          usernames: [other_user.username],
        }
      end
      it "works for public channel" do
        expect(Chat::UserChatChannelMembership.find_by(chat_channel_id: public_channel.id, following: true, user_id: other_user.id)).to be_present

        delete "/chat/api/channels/#{public_channel.id}/memberships/#{other_user.username}"

        expect(response.status).to eq(204)

        expect(Chat::UserChatChannelMembership.find_by(chat_channel_id: public_channel.id, following: true, user_id: other_user.id)).to be_nil
      end

      it "works for private channel" do
        expect(GroupUser.where(group_id: CategoryGroup.find_by(category_id: private_channel.chatable.id).group_id).count).to eq(1)

        delete "/chat/api/channels/#{private_channel.id}/memberships/#{other_user.username}"

        expect(response.status).to eq(204)

        expect(GroupUser.where(group_id: CategoryGroup.find_by(category_id: private_channel.chatable.id).group_id).count).to eq(0)
        expect(Chat::UserChatChannelMembership.find_by(chat_channel_id: private_channel.id, following: true, user_id: other_user.id)).to be_nil
      end
    end
    describe "failure" do
      it "fails if the user is not staff" do
        sign_in(third_user)
        delete "/chat/api/channels/#{public_channel.id}/memberships/#{other_user.username}.json"

        expect(response.status).to eq(403)
      end
    end
  end
end
