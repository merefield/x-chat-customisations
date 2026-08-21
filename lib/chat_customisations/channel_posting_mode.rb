# frozen_string_literal: true

module ChatCustomisations
  module ChannelPostingMode
    CUSTOM_FIELD = "x_chat_posting_mode" if !const_defined?(:CUSTOM_FIELD)

    ANYONE = "anyone" if !const_defined?(:ANYONE)
    STAFF_ONLY = "staff_only" if !const_defined?(:STAFF_ONLY)
    STAFF_ONLY_REPLIES_ALLOWED = "staff_only_replies_allowed" if !const_defined?(
      :STAFF_ONLY_REPLIES_ALLOWED,
    )
    MODES = [ANYONE, STAFF_ONLY, STAFF_ONLY_REPLIES_ALLOWED].freeze if !const_defined?(:MODES)

    def x_chat_posting_mode
      custom_fields[CUSTOM_FIELD].presence || ANYONE
    end

    def x_chat_posting_mode=(mode)
      mode = mode.presence || ANYONE
      raise ArgumentError, "Invalid chat posting mode" if !MODES.include?(mode)

      custom_fields[CUSTOM_FIELD] = mode == ANYONE ? nil : mode
      save_custom_fields
    end
  end
end
