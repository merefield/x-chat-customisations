# frozen_string_literal: true

require_relative "page_objects/components/chat_message_creator"
require_relative "page_objects/pages/chat_channel_members"

RSpec.describe "X Chat Customisations direct message member limits" do
  fab!(:admin, :admin)

  let(:chat_page) { PageObjects::Pages::Chat.new }
  let(:channel_members_page) { PageObjects::Pages::ChatChannelMembers.new }
  let(:message_creator) { chat_page.message_creator }

  before do
    SiteSetting.x_chat_customisations_enabled = true
    SiteSetting.chat_allowed_groups = Group::AUTO_GROUPS[:everyone]
    SiteSetting.direct_message_enabled_groups = Group::AUTO_GROUPS[:everyone]
    SiteSetting.chat_max_direct_message_users = 1
    chat_system_bootstrap
  end

  it "allows staff to create a group DM above the configured member limit" do
    extra_member_1 = Fabricate(:user)
    extra_member_2 = Fabricate(:user)

    sign_in(admin)
    visit("/")
    chat_page.prefers_full_page
    chat_page.open_new_message
    message_creator.start_new_group.fill_group_name("staff-room")
    message_creator.select_user(extra_member_1).select_user(extra_member_2).create_group

    expect(page).to have_current_path(%r{/chat/c/staff-room/\d+})
  end

  it "shows staff an infinite group DM member limit" do
    extra_member_1 = Fabricate(:user)

    sign_in(admin)
    visit("/")
    chat_page.prefers_full_page
    chat_page.open_new_message
    message_creator.start_new_group.select_user(extra_member_1)

    expect(message_creator).to have_members_count("1/Infinity")
  end

  it "shows an infinite group DM member limit when the configured limit is zero" do
    extra_member_1 = Fabricate(:user)

    SiteSetting.chat_max_direct_message_users = 0

    sign_in(admin)
    visit("/")
    chat_page.prefers_full_page
    chat_page.open_new_message
    message_creator.start_new_group.select_user(extra_member_1)

    expect(message_creator).to have_members_count("1/Infinity")
  end

  it "allows staff to create a group DM from a user group above the configured member limit" do
    group_member_1 = Fabricate(:user)
    group_member_2 = Fabricate(:user)
    member_group = Fabricate(:public_group, users: [group_member_1, group_member_2])

    sign_in(admin)
    visit("/")
    chat_page.prefers_full_page
    chat_page.open_new_message
    message_creator.filter(member_group.name)
    message_creator.select_result(member_group).fill_group_name("staff-group-room").create_group

    expect(page).to have_current_path(%r{/chat/c/staff-group-room/\d+})
  end

  it "keeps oversized group results enabled for staff in the message creator" do
    group_member_1 = Fabricate(:user)
    group_member_2 = Fabricate(:user)
    member_group = Fabricate(:public_group, users: [group_member_1, group_member_2])

    sign_in(admin)
    visit("/")
    chat_page.prefers_full_page
    chat_page.open_new_message
    message_creator.filter(member_group.name)

    expect(message_creator).to have_enabled_result(member_group)
    expect(message_creator).to have_no_disabled_result(member_group)
  end

  it "allows staff to add a member above the configured member limit" do
    existing_member = Fabricate(:user)
    extra_member_1 = Fabricate(:user)

    channel =
      Fabricate(
        :direct_message_channel,
        slug: "staff-limit",
        users: [admin, existing_member],
        group: false,
      )

    sign_in(admin)
    channel_members_page.open(channel)

    expect(channel_members_page).to have_add_member_button
    channel_members_page.add_member(extra_member_1)

    wait_for(timeout: 5) do
      Chat::UserChatChannelMembership.exists?(chat_channel: channel, user: extra_member_1)
    end

    channel_members_page.open(channel)

    expect(page).to have_current_path("/chat/c/#{channel.slug}/#{channel.id}/info/members")
    expect(page).to have_css(".c-channel-members__list-item.-member", text: extra_member_1.username)
  end

  it "shows staff an infinite add-member limit when the configured member limit is zero" do
    existing_member = Fabricate(:user)
    extra_member_1 = Fabricate(:user)

    SiteSetting.chat_max_direct_message_users = 0

    channel =
      Fabricate(
        :direct_message_channel,
        slug: "staff-zero-limit",
        users: [admin, existing_member],
        group: false,
      )

    sign_in(admin)
    channel_members_page.open(channel)

    expect(channel_members_page).to have_add_member_button
    channel_members_page.open_add_member

    expect(page).to have_css(".chat-message-creator__members-count", text: "0/Infinity")

    find(".chat-message-creator__members-input").fill_in(with: extra_member_1.username)
    find(".chat-message-creator__list-item[data-identifier='u-#{extra_member_1.id}']").click

    expect(page).to have_css(".chat-message-creator__members-count", text: "1/Infinity")
  end

  it "still hides group DM creation for non-staff at the configured member limit" do
    sign_in(Fabricate(:user))

    visit("/")
    chat_page.prefers_full_page
    chat_page.open_new_message

    expect(message_creator).to have_no_new_group_option
  end
end
