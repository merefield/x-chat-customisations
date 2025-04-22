# frozen_string_literal: true
# name: x-chat-customisations
# about: An extension to the Chat plugin that currently suppresses all emails when a user mentions @all
# version: 0.0.21
# authors: Robert Barrow
# url: https://github.com/merefield/x-chat-customisations

enabled_site_setting :x_chat_customisations_enabled
register_asset 'stylesheets/common/x_chat_common.scss'

module ::ChatCustomisations
  PLUGIN_NAME = "chat-customisations".freeze
end

require_relative "lib/chat_customisations/engine"

if respond_to?(:register_svg_icon)
  register_svg_icon "people-group"
end

after_initialize do
  reloadable_patch do
    Chat::Mailer.singleton_class.prepend(ChatCustomisations::ChatMailerExtension)
    Chat::CategoryChannel.include(ChatCustomisations::CategoryChannelExtension)
    Jobs::UserEmail.prepend(ChatCustomisations::UserEmailJobExtension)
    Chat::TrashChannel.prepend(ChatCustomisations::TrashChannelExtension)
    Jobs::Chat::ChannelDelete.prepend(ChatCustomisations::ChannelDeleteJobExtension)
    Chat::Api::ChannelsController.prepend(ChatCustomisations::ApiChannelControllerExtension)
    Chat::AddUsersToChannel.prepend(ChatCustomisations::AddUsersToChannelExtension)
    Chat::Api::ChannelsMembershipsController.prepend(ChatCustomisations::ApiChannelsMembershipsControllerExtension)
    Chat::SearchChatable.prepend(ChatCustomisations::SearchChatableExtension)
  end

  Chat::Engine.routes.append do
    namespace :api, defaults: { format: :json } do
      delete "/channels/:channel_id/memberships/:username" => "channels_memberships#destroy",
             :constraints => {
              username: RouteFormat.username,
            }
    end
  end

  Jobs::Chat::AutoJoinUsers.every 10.minutes
end
