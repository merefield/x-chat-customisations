# frozen_string_literal: true
module ChatCustomisations
  module CategoryChannelExtension
    extend ActiveSupport::Concern

    included do
      after_initialize :default_allow_channel_wide_mentions
    end

    private

    def default_allow_channel_wide_mentions
      self.allow_channel_wide_mentions = false
    end
  end
end
