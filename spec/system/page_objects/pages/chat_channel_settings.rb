# frozen_string_literal: true

require File.expand_path(
          "../../../../../chat/spec/system/page_objects/chat/chat_channel_settings",
          __dir__,
        )

module PageObjects
  module Pages
    class ChatChannelSettings
      NOTIFICATION_SELECTOR = ".c-channel-settings__notifications-selector"

      def select_notification_level_by_name(name)
        ensure_notification_selector_expanded.select_row_by_name(name)
        self
      end

      def has_notification_level_option?(name)
        ensure_notification_selector_expanded.option_names.include?(name)
      end

      def has_no_notification_level_option?(name)
        !ensure_notification_selector_expanded.option_names.include?(name)
      end

      private

      def notification_selector
        @notification_selector ||= PageObjects::Components::SelectKit.new(NOTIFICATION_SELECTOR)
      end

      def ensure_notification_selector_expanded
        notification_selector.expand if notification_selector.is_collapsed?
        notification_selector
      end
    end
  end
end
