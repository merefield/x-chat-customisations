# frozen_string_literal: true

module ChatCustomisations
  module ChannelFetcherExtension
    def secured_public_channel_search(guardian, options = {})
      channels = super

      if options[:filter].blank? && options[:status].blank? && !options.key?(:slugs)
        channels.reorder("chat_channels.name ASC, categories.name ASC")
      else
        channels
      end
    end
  end
end
