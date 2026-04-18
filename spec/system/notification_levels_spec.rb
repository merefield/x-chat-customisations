# frozen_string_literal: true

require_relative "page_objects/pages/chat_channel_settings"

RSpec.describe "X Chat Customisations notification levels" do
  fab!(:current_user, :user)
  fab!(:other_user, :user)
  fab!(:channel_1, :category_channel)

  let(:chat_page) { PageObjects::Pages::Chat.new }
  let(:chat_sidebar_page) { PageObjects::Pages::ChatSidebar.new }
  let(:channel_settings_page) { PageObjects::Pages::ChatChannelSettings.new }
  let(:toasts) { PageObjects::Components::Toasts.new }
  let(:chat_mention_notifications) do
    Notification.where(user: current_user, notification_type: Notification.types[:chat_mention])
  end

  before do
    SiteSetting.navigation_menu = "sidebar"
    chat_system_bootstrap
    channel_1.add(current_user)
    channel_1.add(other_user)
    sign_in(current_user)
  end

  let(:create_message) do
    ->(message) do
      Fabricate(
        :chat_message,
        chat_channel: channel_1,
        user: other_user,
        message:,
        use_service: true,
      )
    end
  end

  it "adds explicit mention to the channel settings notification selector" do
    membership = channel_1.membership_for(current_user)

    chat_page.visit_channel_settings(channel_1)

    expect {
      channel_settings_page.select_notification_level_by_name(
        I18n.t(
          "js.x_chat_customisations.notification_levels.explicit_mention",
          username: current_user.username,
        ),
      )

      expect(toasts).to have_success(I18n.t("js.saved"))
    }.to change { membership.reload.notification_level }.from("mention").to("explicit_mention")
  end

  it "falls back to core settings labels when the plugin is disabled" do
    SiteSetting.x_chat_customisations_enabled = false

    chat_page.visit_channel_settings(channel_1)

    expect(
      channel_settings_page.has_notification_level_option?(
        I18n.t("js.chat.notification_levels.mention"),
      ),
    ).to eq(true)
    expect(
      channel_settings_page.has_no_notification_level_option?(
        I18n.t(
          "js.x_chat_customisations.notification_levels.explicit_mention",
          username: current_user.username,
        ),
      ),
    ).to eq(true)
  end

  it "adds explicit mention to the sidebar notification menu" do
    membership = channel_1.membership_for(current_user)

    chat_page.visit_channel(channel_1)

    notification_menu = chat_sidebar_page.open_notification_settings(channel_1)

    expect(
      notification_menu.has_option?(
        ".chat-channel-sidebar-link-menu__notification-level-mention",
        I18n.t(
          "js.x_chat_customisations.notification_levels.mention",
          username: current_user.username,
        ),
      ),
    ).to eq(true)
    expect(
      notification_menu.has_option?(
        ".chat-channel-sidebar-link-menu__notification-level-explicit-mention",
        I18n.t(
          "js.x_chat_customisations.notification_levels.explicit_mention",
          username: current_user.username,
        ),
      ),
    ).to eq(true)

    expect { chat_sidebar_page.set_notification_level("explicit-mention") }.to change {
      membership.reload.notification_level
    }.from("mention").to("explicit_mention")
  end

  it "falls back to core sidebar labels when the plugin is disabled" do
    SiteSetting.x_chat_customisations_enabled = false

    chat_page.visit_channel(channel_1)

    notification_menu = chat_sidebar_page.open_notification_settings(channel_1)

    expect(
      notification_menu.has_option?(
        ".chat-channel-sidebar-link-menu__notification-level-mention",
        I18n.t("js.chat.notification_levels.mention"),
      ),
    ).to eq(true)
    expect(
      notification_menu.has_no_option?(
        ".chat-channel-sidebar-link-menu__notification-level-explicit-mention",
      ),
    ).to eq(true)
  end

  it "suppresses @all notifications while keeping direct mentions after selecting explicit mention" do
    Jobs.run_immediately!
    set_subfolder "/discuss"
    channel_1.update!(allow_channel_wide_mentions: true)

    membership = channel_1.membership_for(current_user)

    chat_page.visit_channel(channel_1)

    expect {
      chat_sidebar_page.open_notification_settings(channel_1)
      chat_sidebar_page.set_notification_level("explicit-mention")
    }.to change { membership.reload.notification_level }.from("mention").to("explicit_mention")

    create_message.call("this is fine @all")

    expect(chat_mention_notifications.count).to eq(0)

    visit("/discuss")
    expect(page).to have_no_css(".chat-header-icon .chat-channel-unread-indicator.-urgent")

    direct_message = create_message.call("this is fine @#{current_user.username}")

    expect(chat_mention_notifications.count).to eq(1)

    visit("/discuss")
    find(".header-dropdown-toggle.current-user").click

    within("#user-menu-button-chat-notifications") do |panel|
      expect(panel).to have_content(1)
      panel.click
    end

    expect(find("#quick-access-chat-notifications")).to have_link(
      I18n.t("js.notifications.popup.chat_mention.direct", channel: channel_1.name),
      href: "/discuss/chat/c/#{channel_1.slug}/#{channel_1.id}/#{direct_message.id}",
    )
  end
end
