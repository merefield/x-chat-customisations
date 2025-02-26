# frozen_string_literal: true
# name: x-chat-customisations
# about: An extension to the Chat plugin that currently suppresses all emails when a user mentions @all
# version: 0.0.5
# authors: Robert Barrow
# url: https://github.com/merefield/

enabled_site_setting :x_chat_customisations_enabled

module ::ChatCustomisations
  PLUGIN_NAME = "chat-customisations".freeze
end

require_relative "lib/chat_customisations/engine"

after_initialize do
  reloadable_patch do
    Chat::Mailer.singleton_class.prepend(ChatCustomisations::ChatMailerExtension)
    Jobs::UserEmail.prepend(ChatCustomisations::UserEmailJobExtension)
  end
end
