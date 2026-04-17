# frozen_string_literal: true

RSpec.describe "X Chat Customisations private channel lifecycle" do
  fab!(:admin, :admin)
  fab!(:member, :user) { Fabricate(:user, username: "private_member") }
  fab!(:dummy_private_category) { Fabricate(:category, name: "Private Channel Template") }

  let(:chat_page) { PageObjects::Pages::Chat.new }
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
    result =
      ChatCustomisations::CreatePrivateCategoryChannel.call!(
        guardian: admin.guardian,
        params: {
          name: channel_name,
          slug: channel_slug,
          description: "Private lifecycle coverage",
          threading_enabled: true,
        },
      )

    channel = result.channel
    category = result.category
    group = result.group

    expect(channel.chatable_id).to eq(category.id)
    expect(category.read_restricted).to eq(true)
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

    chat_page.visit_channel_members(channel)

    expect(chat_page).to have_no_add_member_button

    find(".c-channel-members__filter").fill_in(with: member.username)

    within(".c-channel-members__list-item.-member", text: member.username) do
      find(".-remove-member").click
    end

    expect(page).to have_no_css(".c-channel-members__list-item.-member", text: member.username)

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
