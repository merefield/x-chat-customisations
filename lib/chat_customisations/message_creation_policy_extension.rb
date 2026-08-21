# frozen_string_literal: true

module ChatCustomisations
  module MessageCreationPolicyExtension
    def call
      return super if staff_can_post? || !category_channel? || anyone_can_post?

      case channel.x_chat_posting_mode
      when ChatCustomisations::ChannelPostingMode::STAFF_ONLY
        false
      when ChatCustomisations::ChannelPostingMode::STAFF_ONLY_REPLIES_ALLOWED
        super && reply_requested?
      else
        super
      end
    end

    def reason
      if posting_mode_blocks_message?
        I18n.t("x_chat_customisations.posting_modes.#{channel.x_chat_posting_mode}")
      else
        super
      end
    end

    private

    def staff_can_post?
      guardian.user&.staff?
    end

    def category_channel?
      channel.category_channel?
    end

    def anyone_can_post?
      channel.x_chat_posting_mode == ChatCustomisations::ChannelPostingMode::ANYONE
    end

    def reply_requested?
      context.params.thread_id.present? || context.params.in_reply_to_id.present?
    end

    def posting_mode_blocks_message?
      return false if staff_can_post? || !category_channel?

      channel.x_chat_posting_mode == ChatCustomisations::ChannelPostingMode::STAFF_ONLY ||
        (
          channel.x_chat_posting_mode ==
            ChatCustomisations::ChannelPostingMode::STAFF_ONLY_REPLIES_ALLOWED && !reply_requested?
        )
    end
  end
end
