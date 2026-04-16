# frozen_string_literal: true

RSpec.describe "X Chat Customisations notification levels" do
  fab!(:current_user, :user)
  fab!(:channel_1, :category_channel)

  let(:chat_page) { PageObjects::Pages::Chat.new }
  let(:chat_sidebar_page) { PageObjects::Pages::ChatSidebar.new }
  let(:toasts) { PageObjects::Components::Toasts.new }

  before do
    chat_system_bootstrap
    channel_1.add(current_user)
    sign_in(current_user)
  end

  it "adds explicit mention to the channel settings notification selector" do
    membership = channel_1.membership_for(current_user)

    chat_page.visit_channel_settings(channel_1)

    expect {
      select_kit =
        PageObjects::Components::SelectKit.new(".c-channel-settings__notifications-selector")
      select_kit.expand
      select_kit.select_row_by_name(
        I18n.t(
          "js.x_chat_customisations.notification_levels.explicit_mention",
          username: current_user.username,
        ),
      )

      expect(toasts).to have_success(I18n.t("js.saved"))
    }.to change { membership.reload.notification_level }.from("mention").to("explicit_mention")
  end

  it "adds explicit mention to the sidebar notification menu" do
    membership = channel_1.membership_for(current_user)

    chat_page.visit_channel(channel_1)

    expect {
      chat_sidebar_page.open_notification_settings(channel_1)
      chat_sidebar_page.set_notification_level("explicit-mention")
    }.to change { membership.reload.notification_level }.from("mention").to("explicit_mention")
  end
end
