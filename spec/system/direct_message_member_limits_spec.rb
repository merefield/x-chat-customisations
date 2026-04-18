# frozen_string_literal: true

RSpec.describe "X Chat Customisations direct message member limits" do
  fab!(:admin, :admin)

  let(:chat_page) { PageObjects::Pages::Chat.new }

  before do
    SiteSetting.x_chat_customisations_enabled = true
    SiteSetting.chat_allowed_groups = Group::AUTO_GROUPS[:everyone]
    SiteSetting.direct_message_enabled_groups = Group::AUTO_GROUPS[:everyone]
    SiteSetting.chat_max_direct_message_users = 1
    chat_system_bootstrap
    sign_in(admin)
  end

  def select_member(user)
    find(".chat-message-creator__members-input").fill_in(with: user.username)
    find(".chat-message-creator__list-item[data-identifier='u-#{user.id}']").click
  end

  it "allows staff to create a group message above the configured member limit" do
    extra_member_1 = Fabricate(:user)
    extra_member_2 = Fabricate(:user)

    visit("/")
    chat_page.prefers_full_page
    chat_page.open_new_message
    find("#new-group-chat").click
    find(".chat-message-creator__new-group-header__input").fill_in(with: "staff-room")

    select_member(extra_member_1)
    select_member(extra_member_2)

    find(".create-chat-group").click

    expect(page).to have_current_path(%r{/chat/c/staff-room/\d+})
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

    chat_page.visit_channel_members(channel)

    expect(chat_page).to have_add_member_button

    find(".c-channel-members__list-item.-add-member").click
    select_member(extra_member_1)
    page.execute_script("document.querySelector('.add-to-channel').click()")

    wait_for(timeout: 5) do
      Chat::UserChatChannelMembership.exists?(chat_channel: channel, user: extra_member_1)
    end

    chat_page.visit_channel_members(channel)

    expect(page).to have_current_path("/chat/c/#{channel.slug}/#{channel.id}/info/members")
    expect(page).to have_css(".c-channel-members__list-item.-member", text: extra_member_1.username)
  end
end
