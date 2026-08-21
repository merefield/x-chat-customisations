# frozen_string_literal: true

RSpec.describe "X Chat Customisations create channel modal" do
  fab!(:admin, :admin)
  fab!(:default_category) { Fabricate(:category, name: "Default Channel Category") }
  fab!(:dummy_private_category) { Fabricate(:category, name: "Private Channel Template") }

  let(:chat_page) { PageObjects::Pages::Chat.new }
  let(:channel_modal) { PageObjects::Modals::ChatChannelCreate.new }
  let(:category_chooser) { PageObjects::Components::SelectKit.new(".category-chooser") }

  before do
    chat_system_bootstrap
    SiteSetting.x_chat_customisations_channel_creation_default_category_id = default_category.id
    sign_in(admin)
  end

  it "prefills the configured category and hides the threading toggle" do
    chat_page.visit_browse
    chat_page.new_channel_button.click

    expect(category_chooser).to have_selected_name(default_category.name)
    expect(page).to have_no_css(".chat-modal-create-channel__control.-threading-toggle")
  end

  it "creates threaded channels in the configured default category" do
    chat_page.visit_browse
    chat_page.new_channel_button.click

    channel_modal.fill_name("Default Category Threaded Channel")
    channel_modal.fill_slug("default-category-threaded-channel")
    channel_modal.fill_description("Created from the default category selection")
    channel_modal.click_primary_button

    channel = Chat::Channel.find_by!(slug: "default-category-threaded-channel")

    expect(channel.chatable_id).to eq(default_category.id)
    expect(channel.threading_enabled).to eq(true)
    expect(page).to have_current_path(chat.channel_path(channel.slug, channel.id))
  end

  it "creates private channels from the modal when the default category is the private template" do
    SiteSetting.x_chat_customisations_private_chat_dummy_category_id = dummy_private_category.id
    SiteSetting.x_chat_customisations_channel_creation_default_category_id =
      dummy_private_category.id

    chat_page.visit_browse
    chat_page.new_channel_button.click

    channel_modal.fill_name("Private Modal")
    wait_for_attribute(channel_modal.slug_input, :placeholder, "private-modal")
    channel_modal.fill_slug("private-modal")
    channel_modal.fill_description("Created through the browser modal")
    page.execute_script(
      "document.querySelector('.chat-modal-create-channel .btn-primary.create').click()",
    )

    wait_for(timeout: 5) { Chat::Channel.exists?(slug: "private-modal") }

    channel = Chat::Channel.find_by!(slug: "private-modal")
    category = Category.find_by!(name: "Private Modal")
    group = Group.find_by!(name: "private_modal")

    expect(channel.chatable_id).to eq(category.id)
    expect(category.read_restricted).to eq(true)
    expect(group).to be_present
    expect(page).to have_current_path(chat.channel_path(channel.slug, channel.id))
  end
end
