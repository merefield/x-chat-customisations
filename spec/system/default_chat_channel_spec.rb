# frozen_string_literal: true

RSpec.describe "X Chat Customisations default chat channel" do
  fab!(:admin, :admin)
  fab!(:current_user, :user)
  fab!(:default_channel) { Fabricate(:chat_channel, name: "Default Landing Channel") }
  fab!(:last_channel) { Fabricate(:chat_channel, name: "Previous User Channel") }
  fab!(:third_channel) { Fabricate(:chat_channel, name: "Other Public Channel") }

  let(:chat_page) { PageObjects::Pages::Chat.new }
  let(:default_channel_chooser) do
    PageObjects::Components::SelectKit.new(".x-chat-default-channel-form .chat-channel-chooser")
  end

  before do
    current_user.upsert_custom_fields(::Chat::LAST_CHAT_CHANNEL_ID => last_channel.id)
    current_user.user_option.update(
      chat_separate_sidebar_mode: UserOption.chat_separate_sidebar_modes[:never],
    )

    chat_system_bootstrap(current_user, [default_channel, last_channel, third_channel])
  end

  it "opens the configured default channel when another user visits Chat on desktop" do
    SiteSetting.x_chat_customisations_default_chat_channel_id = default_channel.id
    sign_in(current_user)

    chat_page.open

    expect(page).to have_current_path(chat.channel_path(default_channel.slug, default_channel.id))
  end

  it "uses the channel an admin chooses on the Default channel settings page" do
    sign_in(admin)

    visit("/admin/plugins/chat/default-channel")
    default_channel_chooser.expand

    expect(default_channel_chooser.option_names).to include(
      default_channel.title,
      last_channel.title,
      third_channel.title,
    )

    default_channel_chooser.select_row_by_name(third_channel.title)

    expect(default_channel_chooser).to have_selected_name(third_channel.title)
    expect(SiteSetting.x_chat_customisations_default_chat_channel_id).to eq(third_channel.id)

    sign_in(current_user)
    chat_page.open

    expect(page).to have_current_path(chat.channel_path(third_channel.slug, third_channel.id))
  end
end
