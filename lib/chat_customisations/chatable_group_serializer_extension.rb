# frozen_string_literal: true
module ChatCustomisations
  module ChatableGroupSerializerExtension
    def can_chat
      # + 1 for current user
      # remove restriction on numbers
      chat_enabled # && chat_enabled_user_count + 1 <= SiteSetting.chat_max_direct_message_users
    end
  end
end
