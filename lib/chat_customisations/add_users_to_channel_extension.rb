# frozen_string_literal: true
module ChatCustomisations
  module AddUsersToChannelExtension
    def can_add_users_to_channel(guardian:, channel:)
      return true if guardian.user.staff? && channel.category_channel?

      channel.joined_by?(guardian.user) && channel.direct_message_channel? &&
        (channel.chatable.group? || channel.messages_count == 0)
    end

    def fetch_target_users(params:, channel:, guardian:)
      target_groups =
        if params.groups.present?
          Group
            .where(name: params.groups)
            .visible_groups(guardian.user)
            .members_visible_groups(guardian.user)
            .pluck(:name)
        end

      target_users =
        ::Chat::UsersFromUsernamesAndGroupsQuery.call(
          usernames: params.usernames,
          groups: target_groups,
          excluded_user_ids:
            (
              if channel.direct_message_channel?
                channel.chatable.direct_message_users.pluck(:user_id)
              else
                []
              end
            ),
          dm_channel: channel.direct_message_channel?,
        )

      return target_users if !channel.direct_message_channel?

      target_users + channel.chatable.users.where.not(id: guardian.user)
    end

    def create_memberships(channel:, target_users:)
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
        .insert_all(
          memberships,
          unique_by: %i[user_id chat_channel_id],
          returning: Arel.sql("user_id, (xmax = '0') as inserted"),
        )
        .select { |row| row["inserted"] }
        .map { |row| row["user_id"] }

      added_users = target_users.select { |user| context.added_user_ids.include?(user.id) }

      if channel.chatable.is_a?(Category) && channel.chatable.read_restricted
        cg = CategoryGroup.find_by(category_id: channel.chatable.id)

        if cg&.group
          group = cg.group
          existing_user_ids = group.user_ids

          member_candidates = added_users.reject { |user| existing_user_ids.include?(user.id) }
          group.users << member_candidates unless member_candidates.empty?
        end
      end

      return if !channel.direct_message_channel?

      ::Chat::DirectMessageUser.insert_all(
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

    def notice_channel(guardian:, channel:, target_users:)
      if guardian.user.staff? && channel.category_channel? && channel.x_chat_silent_member_adds
        return
      end

      super
    end
  end
end
