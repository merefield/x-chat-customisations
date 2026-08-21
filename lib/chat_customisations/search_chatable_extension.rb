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
        channel =
          Chat::Channel.includes(:chatable).find_by(id: params.excluded_memberships_channel_id)

        if channel && guardian.can_preview_chat_channel?(channel)
          user_search =
            user_search.where(
              "NOT EXISTS (SELECT 1 FROM user_chat_channel_memberships WHERE user_id = users.id AND following = 'true' AND chat_channel_id = ?)",
              params.excluded_memberships_channel_id,
            )
        end
      end

      filter_term = params.term.to_s
      like_term = User.sanitize_sql_like(filter_term)
      escaped_exact = User.connection.quote(filter_term)
      escaped_prefix = User.connection.quote("#{like_term}%")

      select_sql = <<~SQL
        users.*,
        CASE
          WHEN users.username_lower = #{escaped_exact} THEN #{Chat::ChannelFetcher::MATCH_QUALITY_EXACT}
          WHEN users.username_lower LIKE #{escaped_prefix} THEN #{Chat::ChannelFetcher::MATCH_QUALITY_PREFIX}
          ELSE #{Chat::ChannelFetcher::MATCH_QUALITY_PARTIAL}
        END AS match_quality
      SQL

      user_search.select(select_sql).reorder("match_quality ASC, users.username_lower ASC")
    end
  end
end
