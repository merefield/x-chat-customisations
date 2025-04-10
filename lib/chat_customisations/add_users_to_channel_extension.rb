# frozen_string_literal: true
module ChatCustomisations
  module AddUsersToChannelExtension

    def can_add_users_to_channel(guardian:, channel:)
      guardian.user.staff? &&
      ((channel.direct_message_channel? && channel.chatable.group) ||
      channel.chatable.is_a?(Category))
      # (guardian.user.admin? || channel.joined_by?(guardian.user)) &&
      #   channel.direct_message_channel? && channel.chatable.group
    end

    def fetch_target_users(params:, channel:)
      ::Chat::UsersFromUsernamesAndGroupsQuery.call(
        usernames: params.usernames,
        groups: params.groups,
        excluded_user_ids: channel.chatable.is_a?(Category) ? [] : channel.chatable.direct_message_users.pluck(:user_id),
        dm_channel: channel.direct_message_channel?,
      )
    end

    def upsert_memberships(channel:, target_users:)
      only_mentions = ::Chat::UserChatChannelMembership::NOTIFICATION_LEVELS[:mention]

      memberships =
        target_users.map do |user|
          {
            user_id: user.id,
            chat_channel_id: channel.id,
            muted: false,
            following: true,
            notification_level: only_mentions,
            created_at: Time.zone.now,
            updated_at: Time.zone.now,
          }
        end

      if memberships.blank?
        context[:added_user_ids] = []
        return
      end

      context[:added_user_ids] = ::Chat::UserChatChannelMembership
        .upsert_all(
          memberships,
          unique_by: %i[user_id chat_channel_id],
          returning: Arel.sql("user_id, (xmax = '0') as inserted"),
        )
        .select { |row| row["inserted"] }
        .map { |row| row["user_id"] }

      if channel.chatable.is_a?(Category) && channel.chatable.read_restricted
        cg = CategoryGroup.find_by(category_id: channel.chatable.id)

        if cg&.group
          group = cg.group
          existing_user_ids = group.user_ids

          member_candidates = target_users.reject { |user| existing_user_ids.include?(user.id) }
          group.users << member_candidates unless member_candidates.empty?
        end
      end

      ::Chat::DirectMessageUser.upsert_all(
        context.added_user_ids.map do |id|
          {
            user_id: id,
            direct_message_channel_id: channel.chatable.id,
            created_at: Time.zone.now,
            updated_at: Time.zone.now,
          }
        end,
        unique_by: %i[direct_message_channel_id user_id],
      )
    end
  end
end
