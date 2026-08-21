# frozen_string_literal: true

require File.expand_path(
          "../../../../../chat/spec/system/page_objects/chat/chat_channel_settings",
          __dir__,
        )

module PageObjects
  module Pages
    class ChatChannelSettings
      NOTIFICATION_SELECTOR = ".c-channel-settings__notifications-selector"
      POSTING_MODE_SELECTOR = ".c-channel-settings__posting-mode-selector"
      SILENT_MEMBER_ADDS_SELECTOR = ".c-channel-settings__silent-member-adds-switch"

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

      def select_posting_mode_by_name(name)
        ensure_posting_mode_selector_expanded.select_row_by_name(name)
        self
      end

      def has_posting_mode_selector?
        has_css?(POSTING_MODE_SELECTOR)
      end

      def has_no_posting_mode_selector?
        has_no_css?(POSTING_MODE_SELECTOR)
      end

      def toggle_silent_member_adds
        PageObjects::Components::DToggleSwitch.new(SILENT_MEMBER_ADDS_SELECTOR).toggle
        self
      end

      def has_silent_member_adds_toggle?
        has_css?(SILENT_MEMBER_ADDS_SELECTOR)
      end

      def has_no_silent_member_adds_toggle?
        has_no_css?(SILENT_MEMBER_ADDS_SELECTOR)
      end

      private

      def notification_selector
        @notification_selector ||= PageObjects::Components::SelectKit.new(NOTIFICATION_SELECTOR)
      end

      def ensure_notification_selector_expanded
        notification_selector.expand if notification_selector.is_collapsed?
        notification_selector
      end

      def posting_mode_selector
        PageObjects::Components::SelectKit.new(POSTING_MODE_SELECTOR)
      end

      def ensure_posting_mode_selector_expanded
        selector = posting_mode_selector
        selector.expand if selector.is_collapsed?
        selector
      end
    end
  end
end
