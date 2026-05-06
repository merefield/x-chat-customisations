# frozen_string_literal: true
# name: x-chat-customisations
# about: An extension to the Chat plugin that currently suppresses all emails when a user mentions @all
# version: 0.0.24
# authors: Robert Barrow
# url: https://github.com/merefield/x-chat-customisations

enabled_site_setting :x_chat_customisations_enabled
register_asset "stylesheets/common/x_chat_common.scss"

module ::ChatCustomisations
  PLUGIN_NAME = "chat-customisations".freeze
end

require_relative "lib/chat_customisations/engine"

register_svg_icon "people-group" if respond_to?(:register_svg_icon)

after_initialize do
  require_relative "lib/chat_customisations/channels_memberships_by_username_controller"
  require_relative "lib/chat_customisations/add_users_to_channel_contract_extension"
  require_relative "lib/chat_customisations/guardian_extension"
  require_relative "lib/chat_customisations/remove_user_from_channel_extension"

  reloadable_patch do
    Guardian.prepend(ChatCustomisations::GuardianExtension)
    Chat::Mailer.singleton_class.prepend(ChatCustomisations::ChatMailerExtension)
    Chat::ChatableGroupSerializer.prepend(ChatCustomisations::ChatableGroupSerializerExtension)
    Chat::CategoryChannel.include(ChatCustomisations::CategoryChannelExtension)
    Jobs::UserEmail.prepend(ChatCustomisations::UserEmailJobExtension)
    Chat::TrashChannel.prepend(ChatCustomisations::TrashChannelExtension)
    Jobs::Chat::ChannelDelete.prepend(ChatCustomisations::ChannelDeleteJobExtension)
    Chat::Api::ChannelsController.prepend(ChatCustomisations::ApiChannelControllerExtension)
    Chat::AddUsersToChannel.prepend(ChatCustomisations::AddUsersToChannelExtension)
    ChatCustomisations::AddUsersToChannelContractExtension.remove_usernames_length_validator!
    Chat::RemoveUserFromChannel.prepend(ChatCustomisations::RemoveUserFromChannelExtension)
    Chat::SearchChatable.prepend(ChatCustomisations::SearchChatableExtension)
    Jobs::Chat::NotifyMentioned.prepend(ChatCustomisations::NotifyMentionedJobExtension)
  end

  Chat::Engine.routes.append do
    namespace :api, defaults: { format: :json } do
      delete "/channels/:channel_id/memberships/by-username/:username" =>
               "channels_memberships_by_username#destroy",
             :constraints => {
               username: RouteFormat.username,
             }
    end
  end

  Jobs::Chat::AutoJoinUsers.every 10.minutes
end
