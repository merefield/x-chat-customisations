# frozen_string_literal: true

require File.expand_path(
          "../../../../../chat/spec/system/page_objects/chat/components/message_creator",
          __dir__,
        )

module PageObjects
  module Components
    module Chat
      class MessageCreator
        NEW_GROUP_SELECTOR = "#new-group-chat"
        NEW_GROUP_NAME_SELECTOR = ".chat-message-creator__new-group-header__input"
        MEMBERS_INPUT_SELECTOR = ".chat-message-creator__members-input"
        CREATE_GROUP_SELECTOR = ".create-chat-group"

        def has_new_group_option?
          component.has_css?(NEW_GROUP_SELECTOR)
        end

        def has_no_new_group_option?
          component.has_no_css?(NEW_GROUP_SELECTOR)
        end

        def start_new_group
          component.find(NEW_GROUP_SELECTOR).click
          self
        end

        def fill_group_name(name)
          component.find(NEW_GROUP_NAME_SELECTOR).fill_in(with: name)
          self
        end

        def select_user(user)
          component.find(MEMBERS_INPUT_SELECTOR).fill_in(with: user.username)
          click_row(user)
          self
        end

        def select_group(group)
          component.find(MEMBERS_INPUT_SELECTOR).fill_in(with: group.name)
          click_row(group)
          self
        end

        def select_result(chatable)
          click_row(chatable)
          self
        end

        def has_enabled_result?(chatable)
          listing?(chatable, enabled: true)
        end

        def has_disabled_result?(chatable)
          listing?(chatable, disabled: true)
        end

        def has_no_disabled_result?(chatable)
          not_listing?(chatable, disabled: true)
        end

        def has_members_count?(text)
          component.has_css?(".chat-message-creator__members-count", text: text)
        end

        def create_group
          component.find(CREATE_GROUP_SELECTOR).click
          self
        end
      end
    end
  end
end
