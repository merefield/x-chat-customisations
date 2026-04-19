# frozen_string_literal: true
module ChatCustomisations
  module CategoryChannelExtension
    extend ActiveSupport::Concern

    included { before_validation :default_allow_channel_wide_mentions, on: :create }

    private

    def default_allow_channel_wide_mentions
      self.allow_channel_wide_mentions = false
    end
  end
end
