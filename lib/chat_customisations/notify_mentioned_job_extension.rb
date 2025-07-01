module ChatCustomisations
  module NotifyMentionedJobExtension

    NOTIFICATION_LEVELS = { never: 0, mention: 1, always: 2, explicit_mention: 3 }.freeze

    def build_data_for(membership, identifier_type:)
      data = {
        chat_message_id: @chat_message.id,
        chat_channel_id: @chat_channel.id,
        mentioned_by_username: @creator.username,
        is_direct_message_channel: @is_direct_message_channel,
      }

      data[:chat_thread_id] = @chat_message.thread_id if @chat_message.in_thread?

      if !@is_direct_message_channel
        data[:chat_channel_title] = @chat_channel.title(membership.user)
        data[:chat_channel_slug] = @chat_channel.slug
      end

      return data if identifier_type == :direct_mentions

      return nil if ::Chat::UserChatChannelMembership.find_by(
        user_id: membership.user_id,
        chat_channel_id: @chat_channel.id,
      ).notification_level == "explicit_mention" # Skip if explicit mention is set where user has opted out of here/all mentions

      case identifier_type
      when :here_mentions
        data[:identifier] = "here"
      when :global_mentions
        data[:identifier] = "all"
      else
        data[:identifier] = identifier_type if identifier_type
        data[:is_group_mention] = true
      end

      data
    end

    def create_notification!(membership, mention, mention_type)
      notification_data = build_data_for(membership, identifier_type: mention_type)
      return nil if notification_data.nil? # Skip if no data to notify
      is_read = ::Chat::Notifier.user_has_seen_message?(membership, @chat_message.id)
      notification =
        ::Notification.create!(
          notification_type: ::Notification.types[:chat_mention],
          user_id: membership.user_id,
          high_priority: true,
          data: notification_data.to_json,
          read: is_read,
        )

      mention.notifications << notification

      notification
    end

    def process_mentions(user_ids, mention_type)
      memberships = get_memberships(user_ids)

      memberships.each do |membership|
        mention = find_mention(@chat_message, mention_type, membership.user.id)
        if mention.present?
          notification = create_notification!(membership, mention, mention_type)
          send_notifications(membership, mention_type) if notification.present?
        end
      end
    end
  end
end