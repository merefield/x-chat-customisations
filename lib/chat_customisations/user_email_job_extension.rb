# frozen_string_literal: true
module ChatCustomisations
  module UserEmailJobExtension
    def send_user_email(args)
      ##TODO remove this temporary logging
      user = User.find_by(id: args[:user_id])
      message = "Chat Customisations: send_user_email called with args: #{args} and user email: #{user.primary_email.email} on #{ENV["DISCOURSE_HOSTNAME"]}"
      Rails.logger.warn("#{message}")

      if args[:type] == "chat_summary" && !SiteSetting.x_chat_customisations_chat_summary_emails_enabled
        return skip(SkippedEmailLog.reason_types[:custom])
      end

      #now pass back control
      super
    end
  end
end
