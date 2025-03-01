# frozen_string_literal: true

require 'sidekiq/testing'

describe Chat::Mailer do
  fab!(:user) { Fabricate(:user, last_seen_at: 1.hour.ago) }
  fab!(:user_1) { Fabricate(:user, last_seen_at: 1.hour.ago) }
  fab!(:user_2) { Fabricate(:user, last_seen_at: 1.hour.ago) }
  fab!(:user_3) { Fabricate(:user, last_seen_at: 1.hour.ago) }
  fab!(:other) { Fabricate(:user) }

  fab!(:group) do
    Fabricate(:group, mentionable_level: Group::ALIAS_LEVELS[:everyone], users: [user, user_1, user_2, user_3])
  end

  fab!(:followed_channel) { Fabricate(:category_channel) }
  fab!(:job) { :user_email }
  fab!(:args) { { type: :chat_summary, user_id: user.id, force_respect_seen_recently: true } }
  let(:args_json) do
    { 
      "type" => "chat_summary",  # Use string instead of symbol
      "user_id" => user.id,      # Integer is fine
      "force_respect_seen_recently" => true # Boolean is fine
    }
  end

  before do
    SiteSetting.chat_enabled = true
    SiteSetting.chat_allowed_groups = Group::AUTO_GROUPS[:everyone]
  end

  def expect_enqueued
    expect {
      expect_enqueued_with(job:, args:) { described_class.send_unread_mentions_summary }
    }.to_not output.to_stderr_from_any_process
    expect(Jobs::UserEmail.jobs.size).to eq(1)
  end

  def expect_skipped_in_email_log
    expect { Jobs::UserEmail.perform_async(args_json) }.to change { SkippedEmailLog.count }.by(1)
  end

  def expect_not_enqueued
    expect_not_enqueued_with(job:, args:) { described_class.send_unread_mentions_summary }
  end

  # This helper is much faster than `Fabricate(:chat_message_with_service, ...)`
  def create_message(chat_channel, message, mention_klass = nil)
    chat_message = Fabricate(:chat_message, user: other, chat_channel:, message:)

    if mention_klass
      notification_type = Notification.types[:chat_mention]

      Fabricate(
        :chat_mention_notification,
        notification: Fabricate(:notification, user:, notification_type:),
        chat_mention: mention_klass.find_by(chat_message:),
      )
    end

    chat_message
  end

  describe "in a followed channel" do
    before do
      followed_channel.add(user)
      followed_channel.add(user_1)
      followed_channel.add(user_2)
      followed_channel.add(user_3)
    end

    describe "there is a new message" do
      let!(:chat_message) { create_message(followed_channel, "hello y'all :wave:") }

      it "does not queue a chat summary" do
        expect_not_enqueued
      end
    end

    describe "user is @direct mentioned" do
      let!(:chat_message) do
        create_message(followed_channel, "hello @#{user.username}", Chat::UserMention)
      end

      it "queues a chat summary email" do
        expect_enqueued
      end

      it "does not queue a chat summary when chat is globally disabled" do
        SiteSetting.chat_enabled = false
        expect_not_enqueued
      end

      it "does not queue a chat summary when this is disabled in the plugin" do
        SiteSetting.x_chat_customisations_chat_summary_emails_enabled = false
        Sidekiq::Testing.inline!
        expect_skipped_in_email_log
        Sidekiq::Testing.fake!
      end

      it "does not queue a chat summary email when user has chat disabled" do
        user.user_option.update!(chat_enabled: false)
        expect_not_enqueued
      end

      it "does not queue a chat summary email when user has chat email frequency = never" do
        user.user_option.update!(chat_email_frequency: UserOption.chat_email_frequencies[:never])
        expect_not_enqueued
      end

      it "does not queue a chat summary email when user has email level = never" do
        user.user_option.update!(email_level: UserOption.email_level_types[:never])
        expect_not_enqueued
      end

      it "does not queue a chat summary email when chat message has been deleted" do
        chat_message.trash!
        expect_not_enqueued
      end

      it "does not queue a chat summary email when chat message is older than 1 week" do
        chat_message.update!(created_at: 2.weeks.ago)
        expect_not_enqueued
      end

      it "does not queue a chat summary email when chat channel has been deleted" do
        followed_channel.trash!
        expect_not_enqueued
      end

      it "does not queue a chat summary email when user is not part of chat allowed groups" do
        SiteSetting.chat_allowed_groups = Group::AUTO_GROUPS[:admins]
        expect_not_enqueued
      end

      it "does not queue a chat summary email when user has read the mention notification" do
        Notification.find_by(
          user: user,
          notification_type: Notification.types[:chat_mention],
        ).update!(read: true)

        expect_not_enqueued
      end

      it "does not queue a chat summary email when user has been seen in the past 15 minutes" do
        user.update!(last_seen_at: 5.minutes.ago)
        expect_not_enqueued
      end

      it "does not queue a chat summary email when user has read the message" do
        followed_channel.membership_for(user).update!(last_read_message_id: chat_message.id)
        expect_not_enqueued
      end

      it "does not queue a chat summary email when user has received an email for this message" do
        followed_channel.membership_for(user).update!(
          last_unread_mention_when_emailed_id: chat_message.id,
        )

        expect_not_enqueued
      end

      it "does not queue a chat summary email when user is not active" do
        user.update!(active: false)
        expect_not_enqueued
      end

      it "does not queue a chat summary email when user is staged" do
        user.update!(staged: true)
        expect_not_enqueued
      end

      it "does not queue a chat summary email when user is suspended" do
        user.update!(suspended_till: 1.day.from_now)
        expect_not_enqueued
      end

      it "does not queue a chat summary email when sender has been deleted" do
        other.destroy!
        expect_not_enqueued
      end

      it "does not queue a chat summary email when chat message was created by the SDK" do
        chat_message.update!(created_by_sdk: true)
        expect_not_enqueued
      end

      it "queues a chat summary email even when user has private messages disabled" do
        user.user_option.update!(allow_private_messages: false)
        expect_enqueued
      end
    end

    describe "user is @group mentioned" do
      before { create_message(followed_channel, "hello @#{group.name}", Chat::GroupMention) }

      it "queues a chat summary email" do
        expect_enqueued
      end
    end

    describe "user is @all mentioned" do
      before { create_message(followed_channel, "hello @all", Chat::AllMention) }

      it "queues a chat summary email" do
        expect_not_enqueued
      end
    end
  end
end
