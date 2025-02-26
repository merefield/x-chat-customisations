# frozen_string_literal: true
module ChatCustomisations
  module UserEmailJobExtension
    def send_user_email(args)

      ##TODO remove this temporary logging
      user = User.find_by(id: args[:user_id])
      to_address =
          args[:to_address].presence || user&.primary_email&.email.presence || "no_email_found"
      message = "Chat Customisations: send_user_email called with args: #{args}, user email: #{user.primary_email.email}, to_address: #{to_address} on #{ENV["DISCOURSE_HOSTNAME"]}"
      Rails.logger.warn("#{message}")

      if args[:type] == "chat_summary" && !SiteSetting.x_chat_customisations_chat_summary_emails_enabled
        attributes = {
          email_type: args[:type],
          to_address: to_address,
          user_id: args[:user_id],
          post_id: nil,
          reason_type: SkippedEmailLog.reason_types[:custom],
          custom_reason: "Chat Summary emails are disabled"
        }
        return SkippedEmailLog.create!(attributes)
      end

      #now pass back control
      super
    end
  end
end
