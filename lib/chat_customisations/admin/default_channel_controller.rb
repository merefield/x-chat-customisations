# frozen_string_literal: true

module ChatCustomisations
  module Admin
    class DefaultChannelController < ::Admin::AdminController
      requires_plugin "x-chat-customisations"

      def show
        render json: default_channel_payload
      end

      def update
        chat_channel_id = params[:chat_channel_id].to_i

        if chat_channel_id.positive?
          raise Discourse::NotFound if !eligible_channels.exists?(id: chat_channel_id)
        end

        SiteSetting.x_chat_customisations_default_chat_channel_id = chat_channel_id

        render json: default_channel_payload
      end

      private

      def default_channel_payload
        {
          chat_channels:
            eligible_channels.map do |channel|
              Chat::ChannelSerializer.new(channel, scope: guardian, root: false).as_json
            end,
          default_chat_channel_id: SiteSetting.x_chat_customisations_default_chat_channel_id,
        }
      end

      def eligible_channels
        Chat::Channel
          .public_channels
          .where(categories: { read_restricted: false })
          .order(Arel.sql("LOWER(COALESCE(chat_channels.name, categories.name))"))
      end
    end
  end
end
