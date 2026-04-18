# frozen_string_literal: true

require_relative "page_objects/pages/chat_channel_members"

RSpec.describe "X Chat Customisations private channel lifecycle" do
  fab!(:admin, :admin)
  fab!(:member, :user) { Fabricate(:user, username: "private_member") }
  fab!(:dummy_private_category) { Fabricate(:category, name: "Private Channel Template") }

  let(:chat_page) { PageObjects::Pages::Chat.new }
  let(:channel_members_page) { PageObjects::Pages::ChatChannelMembers.new }
  let(:channel_modal) { PageObjects::Modals::ChatChannelCreate.new }
  let(:channel_name) { "Private Lifecycle" }
  let(:channel_slug) { "private-lifecycle" }

  before do
    chat_system_bootstrap
    SiteSetting.x_chat_customisations_private_chat_dummy_category_id = dummy_private_category.id
    SiteSetting.x_chat_customisations_channel_creation_default_category_id =
      dummy_private_category.id
    sign_in(admin)
  end

  it "removes a member and deletes the backing records for a private channel" do
    chat_page.visit_browse
    chat_page.new_channel_button.click

    channel_modal.fill_name(channel_name)
    wait_for_attribute(channel_modal.slug_input, :placeholder, channel_slug)
    channel_modal.fill_slug(channel_slug)
    channel_modal.fill_description("Private lifecycle coverage")
    page.execute_script(
      "document.querySelector('.chat-modal-create-channel .btn-primary.create').click()",
    )

    wait_for(timeout: 5) { Chat::Channel.exists?(slug: channel_slug) }

    channel = Chat::Channel.find_by!(slug: channel_slug)
    category = Category.find_by!(name: channel_name)
    group = Group.find_by!(name: channel_name.parameterize(separator: "_"))

    expect(channel.chatable_id).to eq(category.id)
    expect(category.read_restricted).to eq(true)
    expect(page).to have_current_path(channel.url)
    expect(GroupUser.exists?(group:, user: admin, owner: true)).to eq(true)

    Chat::AddUsersToChannel.call!(
      guardian: admin.guardian,
      params: {
        channel_id: channel.id,
        usernames: [member.username],
      },
    )

    expect(Chat::UserChatChannelMembership.exists?(chat_channel: channel, user: member)).to eq(true)
    expect(GroupUser.exists?(group:, user: member)).to eq(true)

    channel_members_page.open(channel)

    expect(channel_members_page).to have_add_member_button

    channel_members_page.filter_members(member.username).remove_member(member.username)

    expect(channel_members_page).to have_no_member(member.username)

    chat_page.visit_channel_settings(channel)
    click_button(I18n.t("js.chat.channel_settings.delete_channel"))
    fill_in("channel-delete-confirm-name", with: channel.name)
    find_button("chat-confirm-delete-channel", disabled: false).click

    expect(page).to have_content(I18n.t("js.chat.channel_delete.process_started"))

    Jobs::Chat::ChannelDelete.new.execute(chat_channel_id: channel.id, channel_name: channel.name)

    expect(Chat::Channel.find_by(id: channel.id)).to be_nil
    expect(Category.find_by(id: category.id)).to be_nil
    expect(Group.find_by(id: group.id)).to be_nil
  end
end
