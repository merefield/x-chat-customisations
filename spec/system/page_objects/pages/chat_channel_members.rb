# frozen_string_literal: true

require File.expand_path("../../../../../chat/spec/system/page_objects/chat/chat", __dir__)

module PageObjects
  module Pages
    class ChatChannelMembers < Chat
      def open(channel)
        visit_channel_members(channel)
        self
      end

      def filter_members(query)
        find(".c-channel-members__filter").fill_in(with: query)
        self
      end

      def open_add_member
        find(".c-channel-members__list-item.-add-member").click
        self
      end

      def add_member(user)
        open_add_member
        find(".chat-message-creator__members-input").fill_in(with: user.username)
        find(".chat-message-creator__list-item[data-identifier='u-#{user.id}']").click
        page.execute_script("document.querySelector('.add-to-channel').click()")
        self
      end

      def remove_member(username)
        within_member_row(username) { click_button(I18n.t("js.chat.channel_info.remove_member")) }

        self
      end

      def has_member?(username)
        page.has_css?(".c-channel-members__list-item.-member", text: username)
      end

      def has_no_member?(username)
        page.has_no_css?(".c-channel-members__list-item.-member", text: username)
      end

      def has_member_count?(count)
        page.has_css?(".c-channel-info__member-count", text: "(#{count})")
      end

      private

      def within_member_row(username, &block)
        page.within(:xpath, member_row_selector(username), &block)
      end

      def member_row_selector(username)
        XPath
          .generate do |xpath|
            xpath.descendant(:li)[
              xpath.attr(:class).contains("-member") & xpath.string.n.contains(username)
            ]
          end
          .to_s
      end
    end
  end
end
