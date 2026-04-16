# frozen_string_literal: true

describe Jobs::Chat::NotifyMentioned do
  subject(:job) { described_class.new }

  fab!(:author, :user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:mentioned_user, :user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:public_channel, :category_channel)

  before do
    [author, mentioned_user].each do |user|
      user.reload
      Fabricate(:user_chat_channel_membership, chat_channel: public_channel, user: user)
    end

    public_channel.membership_for(mentioned_user).update!(
      notification_level: Chat::UserChatChannelMembership::NOTIFICATION_LEVELS[:explicit_mention],
    )
  end

  def create_direct_mention_message
    message =
      Fabricate(
        :chat_message,
        chat_channel: public_channel,
        user: author,
        created_at: 10.minutes.ago,
      )

    Fabricate(:user_chat_mention, chat_message: message, user: mentioned_user)
    message
  end

  def create_global_mention_message
    message =
      Fabricate(
        :chat_message,
        chat_channel: public_channel,
        user: author,
        created_at: 10.minutes.ago,
      )

    Fabricate(:all_chat_mention, chat_message: message)
    message
  end

  def create_here_mention_message
    message =
      Fabricate(
        :chat_message,
        chat_channel: public_channel,
        user: author,
        created_at: 10.minutes.ago,
      )

    Fabricate(:here_chat_mention, chat_message: message)
    message
  end

  def track_desktop_notification(message:, to_notify_ids_map:)
    MessageBus
      .track_publish("/chat/notification-alert/#{mentioned_user.id}") do
        job.execute(
          chat_message_id: message.id,
          timestamp: message.created_at.to_s,
          to_notify_ids_map: to_notify_ids_map,
        )
      end
      .first
  end

  def latest_notification
    Notification.where(
      user: mentioned_user,
      notification_type: Notification.types[:chat_mention],
    ).last
  end

  it "still notifies for direct mentions" do
    message = create_direct_mention_message

    desktop_notification =
      track_desktop_notification(
        message: message,
        to_notify_ids_map: {
          direct_mentions: [mentioned_user.id],
        },
      )

    expect(desktop_notification).to be_present
    expect(latest_notification).to be_present
  end

  it "suppresses notifications for @all mentions" do
    message = create_global_mention_message

    PostAlerter.expects(:push_notification).never

    desktop_notification =
      track_desktop_notification(
        message: message,
        to_notify_ids_map: {
          global_mentions: [mentioned_user.id],
        },
      )

    expect(desktop_notification).to be_nil
    expect(latest_notification).to be_nil
  end

  it "suppresses notifications for @here mentions" do
    message = create_here_mention_message

    PostAlerter.expects(:push_notification).never

    desktop_notification =
      track_desktop_notification(
        message: message,
        to_notify_ids_map: {
          here_mentions: [mentioned_user.id],
        },
      )

    expect(desktop_notification).to be_nil
    expect(latest_notification).to be_nil
  end
end
