# frozen_string_literal: true

module ChatCustomisations
  module ChannelSerializerExtension
    def self.prepended(base)
      base.attributes :x_chat_posting_mode, :x_chat_silent_member_adds
    end

    def x_chat_posting_mode
      object.x_chat_posting_mode
    end

    def include_x_chat_posting_mode?
      object.category_channel?
    end

    def x_chat_silent_member_adds
      object.x_chat_silent_member_adds
    end

    def include_x_chat_silent_member_adds?
      object.category_channel?
    end
  end
end
