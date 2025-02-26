# frozen_string_literal: true
module ChatCustomisations
  module UserEmailJobExtension
    def send_user_email(args)

      # Consider removal if no longer used
      if SiteSetting.x_chat_customisations_enhanced_logging
        user = User.find_by(id: args[:user_id])
        to_address =
            args[:to_address].presence || user&.primary_email&.email.presence || "no_email_found"
        message = "Chat Customisations: send_user_email called with args: #{args}, user email: #{user.primary_email.email}, to_address: #{to_address} on #{ENV["DISCOURSE_HOSTNAME"]}"
        Rails.logger.warn("#{message}")
      end

      if args[:type] == "chat_summary" && !SiteSetting.x_chat_customisations_chat_summary_emails_enabled
        attributes = {
          email_type: args[:type],
          to_address: to_address,
          user_id: args[:user_id],
          post_id: nil,
          reason_type: SkippedEmailLog.reason_types[:custom],
          custom_reason: I18n.t("x_chat_customisations.custom_reasons.chat_summary_emails_disabled"),
        }
        return SkippedEmailLog.create!(attributes)
      end

      # CORE BUG: if we don't set to_address, ultimately the email won't send and will be skipped.
      # This is a core bug and we will need to raise it on Meta.
      if args[:to_address].blank? && user&.primary_email&.email
        args[:to_address] = user&.primary_email&.email
      end

      #now pass back control
      super
    end

    def message_for_email(user, post, type, notification, args = nil)
      if SiteSetting.x_chat_customisations_enhanced_logging
        Rails.logger.warn("Chat Customisations: message_for_email called with user: #{user}, post: #{post}, type: #{type}, notification: #{notification}, args: #{args} on #{ENV["DISCOURSE_HOSTNAME"]}")
      end

      #now pass back control
      super
    end
  end
end
