# frozen_string_literal: true

module ChatCustomisations
  module ChannelSilentMemberAdds
    CUSTOM_FIELD = "x_chat_silent_member_adds" if !const_defined?(:CUSTOM_FIELD)

    def x_chat_silent_member_adds
      custom_fields[CUSTOM_FIELD] == "true"
    end

    def x_chat_silent_member_adds=(enabled)
      custom_fields[CUSTOM_FIELD] = enabled ? "true" : nil
      save_custom_fields
    end
  end
end
