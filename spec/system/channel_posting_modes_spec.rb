# frozen_string_literal: true

require_relative "page_objects/pages/chat_channel_settings"

RSpec.describe "X Chat Customisations channel posting modes" do
  fab!(:admin)
  fab!(:channel, :chat_channel)
  fab!(:user)

  let(:chat_page) { PageObjects::Pages::Chat.new }
  let(:settings_page) { PageObjects::Pages::ChatChannelSettings.new }

  before do
    SiteSetting.x_chat_customisations_enabled = true
    SiteSetting.chat_allowed_groups = Group::AUTO_GROUPS[:everyone]
    channel.add(admin)
    channel.add(user)
    chat_system_bootstrap
  end

  it "allows staff to set the posting mode from category channel settings" do
    sign_in(admin)

    chat_page.visit_channel_settings(channel)

    expect(settings_page).to have_posting_mode_selector

    expect(channel.reload.x_chat_posting_mode).to eq("anyone")

    settings_page.select_posting_mode_by_name(
      I18n.t("js.x_chat_customisations.posting_modes.staff_only_replies_allowed"),
    )

    wait_for(timeout: 5) { channel.reload.x_chat_posting_mode == "staff_only_replies_allowed" }
  end

  it "does not show the posting mode selector for direct messages" do
    direct_message_channel = Fabricate(:direct_message_channel, users: [admin, user])

    sign_in(admin)

    chat_page.visit_channel_settings(direct_message_channel)

    expect(settings_page).to have_no_posting_mode_selector
  end
end
