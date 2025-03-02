# frozen_string_literal: true
module ChatCustomisations
  module ChatMailerExtension

    def send_unread_mentions_summary
      return unless SiteSetting.chat_enabled

      User
        .real
        .activated
        .not_staged
        .not_suspended
        .where(id: users_with_unreads_custom)
        .find_each do |user|
          if DiscoursePluginRegistry.apply_modifier(:chat_mailer_send_summary_to_user, true, user)
            Jobs.enqueue(
              :user_email,
              type: "chat_summary",
              user_id: user.id,
              force_respect_seen_recently: true,
            )
          end
        end
    end

    private

    def users_with_unreads_custom
      groups_join_sql =
        if Chat.allowed_group_ids.include?(Group::AUTO_GROUPS[:everyone])
          ""
        else
          "JOIN group_users gu ON gu.user_id = u.id AND gu.group_id IN (#{Chat.allowed_group_ids.join(",")})"
        end

      DB.query_single <<~SQL
        WITH eligible_users AS (
          SELECT DISTINCT u.id, uo.allow_private_messages
          FROM users u
          JOIN user_options uo ON uo.user_id = u.id#{' '}
          #{groups_join_sql}
          WHERE u.last_seen_at < now() - interval '15 minutes'
          AND uo.chat_enabled
          AND uo.chat_email_frequency = #{UserOption.chat_email_frequencies[:when_away]}
          AND uo.email_level <> #{UserOption.email_level_types[:never]}
        ), channel_messages AS (
          SELECT DISTINCT ON (chat_channel_id) chat_channel_id, cm.id AS first_unread_id, user_id AS sender_id
          FROM chat_messages cm
          JOIN users sender ON sender.id = cm.user_id
          WHERE cm.created_at > now() - interval '1 week'
          AND cm.deleted_at IS NULL
          AND NOT cm.created_by_sdk
          ORDER BY chat_channel_id, cm.id
        ), unread_dms AS (
          SELECT DISTINCT uccm.user_id
          FROM user_chat_channel_memberships uccm
          JOIN chat_channels cc ON cc.id = uccm.chat_channel_id AND cc.deleted_at IS NULL AND cc.chatable_type = 'DirectMessage'
          JOIN channel_messages cm ON cm.chat_channel_id = cc.id AND cm.sender_id <> uccm.user_id
          JOIN eligible_users eu ON eu.id = uccm.user_id AND eu.allow_private_messages
          WHERE NOT uccm.muted
          AND (uccm.last_read_message_id IS NULL OR cm.first_unread_id > uccm.last_read_message_id)
          AND (uccm.last_unread_mention_when_emailed_id IS NULL OR cm.first_unread_id > uccm.last_unread_mention_when_emailed_id)
        ), unread_mentions AS (
          SELECT DISTINCT n.user_id
          FROM notifications n
          JOIN eligible_users eu ON eu.id = n.user_id
          JOIN chat_mention_notifications cmn ON cmn.notification_id = n.id
          JOIN chat_mentions mn ON mn.id = cmn.chat_mention_id
          JOIN chat_messages cm ON cm.id = mn.chat_message_id
            AND cm.deleted_at IS NULL
            AND cm.thread_id IS NULL
            AND NOT cm.created_by_sdk
            AND cm.created_at > now() - interval '1 day'
          JOIN users sender ON sender.id = cm.user_id
          JOIN chat_channels cc ON cc.id = cm.chat_channel_id
            AND cc.deleted_at IS NULL
            AND cc.chatable_type = 'Category'
          JOIN user_chat_channel_memberships uccm ON uccm.chat_channel_id = cc.id
            AND uccm.user_id = n.user_id
            AND NOT uccm.muted
            AND uccm.following
            AND (uccm.last_read_message_id IS NULL OR uccm.last_read_message_id < cm.id)
            AND (uccm.last_unread_mention_when_emailed_id IS NULL OR uccm.last_unread_mention_when_emailed_id < cm.id)
          WHERE NOT n.read
          AND (mn.type IS NULL OR mn.type <> 'Chat::AllMention')
        )
        SELECT user_id FROM unread_dms
        UNION
        SELECT user_id FROM unread_mentions
      SQL
    end
  end
end
