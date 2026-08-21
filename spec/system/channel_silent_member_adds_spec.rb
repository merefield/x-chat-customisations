# frozen_string_literal: true

require_relative "page_objects/pages/chat_channel_members"
require_relative "page_objects/pages/chat_channel_settings"

RSpec.describe "X Chat Customisations silent member adds" do
  fab!(:admin)
  fab!(:channel, :chat_channel)
  fab!(:existing_member) { Fabricate(:user, username: "existing_chat_member") }
  fab!(:added_member) { Fabricate(:user, username: "silent_added_member") }

  let(:chat_page) { PageObjects::Pages::Chat.new }
  let(:members_page) { PageObjects::Pages::ChatChannelMembers.new }
  let(:settings_page) { PageObjects::Pages::ChatChannelSettings.new }

  before do
    SiteSetting.chat_enabled = true
    SiteSetting.chat_allowed_groups = Group::AUTO_GROUPS[:everyone]
    chat_system_bootstrap

    channel.add(admin)
    channel.add(existing_member)

    sign_in(admin)
  end

  it "allows staff to enable silent member adds from category channel settings" do
    chat_page.visit_channel_settings(channel)

    expect(settings_page).to have_silent_member_adds_toggle

    expect { settings_page.toggle_silent_member_adds }.to change {
      channel.reload.x_chat_silent_member_adds
    }.from(false).to(true)
  end

  it "does not show silent member adds for direct messages" do
    direct_message_channel = Fabricate(:direct_message_channel, users: [admin, existing_member])

    chat_page.visit_channel_settings(direct_message_channel)

    expect(settings_page).to have_no_silent_member_adds_toggle
  end

  it "adds members without posting an invite notice when enabled" do
    channel.x_chat_silent_member_adds = true

    members_page.open(channel).add_member(added_member)

    wait_for(timeout: 5) do
      Chat::UserChatChannelMembership.exists?(chat_channel: channel, user: added_member)
    end

    chat_page.visit_channel(channel)

    expect(page).to have_no_text(
      I18n.t(
        "chat.channel.users_invited_to_channel",
        invited_users: "@#{added_member.username}",
        inviting_user: "@#{admin.username}",
        count: 1,
      ),
    )
  end
end
