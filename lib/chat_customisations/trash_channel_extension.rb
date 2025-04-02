# frozen_string_literal: true
module ChatCustomisations
  module TrashChannelExtension
    def enqueue_delete_channel_relations_job(channel:)
      Jobs.enqueue(Jobs::Chat::ChannelDelete, chat_channel_id: channel.id, channel_name: channel.name)
    end
  end
end
