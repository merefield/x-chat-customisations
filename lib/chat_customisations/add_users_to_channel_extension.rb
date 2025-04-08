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
        excluded_user_ids: channel.chatable.is_a?(Category)? [] : channel.chatable.direct_message_users.pluck(:user_id),
        dm_channel: channel.direct_message_channel?,
      )
    end
  end
end
