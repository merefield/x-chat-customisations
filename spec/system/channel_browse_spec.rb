# frozen_string_literal: true

RSpec.describe "X Chat Customisations channel browse" do
  fab!(:current_user, :user)
  fab!(:open_channel) { Fabricate(:chat_channel, name: "Sidebar Channel", status: :open) }
  fab!(:read_only_channel) { Fabricate(:chat_channel, name: "Alpha Channel", status: :read_only) }
  fab!(:closed_channel) { Fabricate(:chat_channel, name: "Beta Channel", status: :closed) }

  let(:chat_page) { PageObjects::Pages::Chat.new }
  let(:browse_page) { PageObjects::Pages::ChatBrowse.new }
  let(:chat_drawer_page) { PageObjects::Pages::ChatDrawer.new }
  let(:sidebar_page) { PageObjects::Pages::ChatSidebar.new }

  before do
    current_user.user_option.update(
      chat_separate_sidebar_mode: UserOption.chat_separate_sidebar_modes[:never],
    )
    sign_in(current_user)
    chat_system_bootstrap(current_user, [open_channel, read_only_channel, closed_channel])
  end

  it "opens the all channels browse view by default" do
    chat_page.visit_browse

    expect(browse_page).to have_current_path("/chat/browse/all")
    expect(browse_page).to have_channel(name: read_only_channel.name)
    expect(browse_page).to have_channel(name: closed_channel.name)
    expect(browse_page.channel_names).to eq(
      [read_only_channel.name, closed_channel.name, open_channel.name],
    )
  end

  it "opens the all channels browse view from the Channels sidebar action" do
    visit("/")
    chat_page.open_from_header
    sidebar_page.open_browse

    expect(chat_drawer_page.browse).to have_channel(name: read_only_channel.name)
    expect(chat_drawer_page.browse).to have_channel(name: closed_channel.name)
  end
end
