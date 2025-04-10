# frozen_string_literal: true
module ChatCustomisations
  module SearchChatableExtension

    SEARCH_RESULT_LIMIT = 20

    def search_users(params, guardian)
      user_search = ::UserSearch.new(params.term, limit: SEARCH_RESULT_LIMIT)

      if params.term.blank?
        user_search = user_search.scoped_users
      else
        user_search = user_search.search
      end

      allowed_bot_user_ids =
        DiscoursePluginRegistry.apply_modifier(:chat_allowed_bot_user_ids, [], guardian)

      user_search = user_search.real(allowed_bot_user_ids: allowed_bot_user_ids)
      user_search = user_search.includes(:user_option)

      if params.excluded_memberships_channel_id
        user_search =
          user_search.where(
            "NOT EXISTS (SELECT 1 FROM user_chat_channel_memberships WHERE user_id = users.id AND following = 'true' AND chat_channel_id = ?)",
            params.excluded_memberships_channel_id,
          )
      end

      user_search
    end
  end
end
