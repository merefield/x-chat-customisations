# frozen_string_literal: true

RSpec.describe Jobs::UserEmail do
  subject(:job) { described_class.new }

  fab!(:user)

  let(:message) { Mail::Message.new }
  let(:sender) { stub(send: true) }

  before do
    SiteSetting.x_chat_customisations_enhanced_logging = false

    job.stubs(:message_for_email).returns([message, nil])
    Email::Sender.stubs(:new).returns(sender)
  end

  describe "#send_user_email" do
    it "logs the resolved user email when to_address is omitted" do
      SiteSetting.x_chat_customisations_enhanced_logging = true

      Rails.logger.expects(:warn).with(includes("to_address: #{user.email}")).once

      job.send_user_email(type: "digest", user_id: user.id)
    end

    it "logs no_email_found when no email can be resolved" do
      SiteSetting.x_chat_customisations_enhanced_logging = true

      Rails.logger.expects(:warn).with(includes("to_address: no_email_found")).once

      job.send_user_email(type: "digest", user_id: User.maximum(:id) + 1)
    end

    it "does not log when enhanced logging is disabled" do
      Rails.logger.expects(:warn).never

      job.send_user_email(type: "digest", user_id: user.id)
    end
  end

  describe "#message_for_email" do
    before do
      job.unstub(:message_for_email)
      EmailLog.stubs(:unique_email_per_post).yields.returns(message)
      UserNotifications.stubs(:forgot_password).returns(message)
    end

    it "logs its arguments when enhanced logging is enabled" do
      SiteSetting.x_chat_customisations_enhanced_logging = true

      Rails.logger.expects(:warn).with(includes("message_for_email called with user: #{user}")).once

      returned_message, error =
        job.message_for_email(user, nil, "forgot_password", nil, email_token: "token")

      expect(returned_message).to eq(message)
      expect(error).to eq(nil)
    end
  end
end
