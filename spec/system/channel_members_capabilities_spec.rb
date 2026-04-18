# frozen_string_literal: true

require_relative "page_objects/pages/chat_channel_members"

RSpec.describe "X Chat Customisations channel member capabilities" do
  fab!(:moderator, :moderator)
  fab!(:private_group) { Fabricate(:group, name: "members_cap_group") }
  fab!(:private_channel) { Fabricate(:private_category_channel, group: private_group) }
  fab!(:existing_member) { Fabricate(:user, username: "existing_chat_member") }
  fab!(:added_member) { Fabricate(:user, username: "remove_target_member") }

  let(:channel_members_page) { PageObjects::Pages::ChatChannelMembers.new }

  before do
    SiteSetting.chat_enabled = true
    SiteSetting.chat_allowed_groups = Group::AUTO_GROUPS[:everyone]
    chat_system_bootstrap

    Fabricate(:group_user, group: private_group, user: moderator)
    Fabricate(:group_user, group: private_group, user: existing_member)

    private_channel.add(moderator)
    private_channel.add(existing_member)

    sign_in(moderator)
  end

  it "allows staff to add members to a private category-backed channel" do
    channel_members_page.open(private_channel)

    expect(channel_members_page).to have_add_member_button

    channel_members_page.add_member(added_member)

    wait_for(timeout: 5) do
      Chat::UserChatChannelMembership.exists?(chat_channel: private_channel, user: added_member)
    end

    expect(GroupUser.exists?(group: private_group, user: added_member)).to eq(true)
  end

  it "allows staff to remove members from a private category-backed channel" do
    Fabricate(:group_user, group: private_group, user: added_member)
    membership = private_channel.add(added_member)

    channel_members_page.open(private_channel).filter_members(added_member.username)
    channel_members_page.remove_member(added_member.username)

    wait_for(timeout: 5) { membership.reload.following == false }

    expect(channel_members_page).to have_no_member(added_member.username)
    expect(GroupUser.exists?(group: private_group, user: added_member)).to eq(false)
  end
end
