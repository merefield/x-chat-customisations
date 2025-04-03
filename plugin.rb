# frozen_string_literal: true
# name: x-chat-customisations
# about: An extension to the Chat plugin that currently suppresses all emails when a user mentions @all
# version: 0.0.17
# authors: Robert Barrow
# url: https://github.com/merefield/x-chat-customisations

enabled_site_setting :x_chat_customisations_enabled
register_asset 'stylesheets/common/x_chat_common.scss'

module ::ChatCustomisations
  PLUGIN_NAME = "chat-customisations".freeze
end

require_relative "lib/chat_customisations/engine"

after_initialize do
  reloadable_patch do
    Chat::Mailer.singleton_class.prepend(ChatCustomisations::ChatMailerExtension)
    Chat::CategoryChannel.include(ChatCustomisations::CategoryChannelExtension)
    Jobs::UserEmail.prepend(ChatCustomisations::UserEmailJobExtension)
    Chat::TrashChannel.prepend(ChatCustomisations::TrashChannelExtension)
    Jobs::Chat::ChannelDelete.prepend(ChatCustomisations::ChannelDeleteJobExtension)
    Chat::Api::ChannelsController.prepend(ChatCustomisations::ApiChannelControllerExtension)
  end

  Jobs::Chat::AutoJoinUsers.every 10.minutes
end
