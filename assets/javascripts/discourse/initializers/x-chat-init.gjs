import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { withPluginApi } from "discourse/lib/plugin-api";
import Category from "discourse/models/category";
import { i18n } from "discourse-i18n";
import { MODES } from "discourse/plugins/chat/discourse/components/chat/message-creator/constants";

export function buildNotificationLevels({
  notificationLevels,
  enabled,
  username,
}) {
  const filteredNotificationLevels = (notificationLevels ?? []).filter(
    (level) => level.value !== "explicit_mention"
  );

  if (!enabled) {
    return filteredNotificationLevels;
  }

  const mentionNotificationLevel = filteredNotificationLevels.find(
    (level) => level.value === "mention"
  ) ?? {
    value: "mention",
  };
  const mentionLevel = {
    ...mentionNotificationLevel,
    name: i18n("x_chat_customisations.notification_levels.mention", {
      username,
    }),
  };
  const explicitMentionLevel = {
    name: i18n("x_chat_customisations.notification_levels.explicit_mention", {
      username,
    }),
    value: "explicit_mention",
  };
  const levelsWithoutMention = filteredNotificationLevels.filter(
    (level) => level.value !== "mention"
  );
  const alwaysIndex = levelsWithoutMention.findIndex(
    (level) => level.value === "always"
  );

  if (alwaysIndex === -1) {
    return [...levelsWithoutMention, mentionLevel, explicitMentionLevel];
  }

  return [
    ...levelsWithoutMention.slice(0, alwaysIndex),
    mentionLevel,
    explicitMentionLevel,
    ...levelsWithoutMention.slice(alwaysIndex),
  ];
}

export function buildSidebarNotificationLevelOptions({
  notificationLevelOptions,
  enabled,
  username,
}) {
  return buildNotificationLevels({
    notificationLevels: notificationLevelOptions,
    enabled,
    username,
  }).map((level) => ({
    ...level,
    className:
      level.className ||
      `chat-channel-sidebar-link-menu__notification-level-${level.value.replaceAll("_", "-")}`,
  }));
}

export function effectiveMaxMembers({
  currentUser,
  maxMembers,
  membersCount = 0,
}) {
  if (!currentUser?.staff) {
    return maxMembers;
  }

  return Math.max(maxMembers, membersCount + 1);
}

export function canStaffBypassGroupLimit({ currentUser, chatable }) {
  return currentUser?.staff && chatable?.type === "group";
}

export default {
  name: "x-chat-init",
  initialize() {
    withPluginApi((api) => {
      api.modifyClass(
        "component:chat/modal/create-channel",
        (Superclass) =>
          class extends Superclass {
            @service siteSettings;

            @tracked
            categoryId =
              this.siteSettings
                .x_chat_customisations_channel_creation_default_category_id;
            @tracked category = Category.findById(this.categoryId);
            @tracked threadingEnabled = true;
            @tracked autoJoinUsers = false;
          }
      );

      api.modifyClass(
        "component:chat/routes/channel-info-settings",
        (Superclass) =>
          class extends Superclass {
            @service currentUser;

            get notificationLevels() {
              return buildNotificationLevels({
                notificationLevels: super.notificationLevels,
                enabled: this.siteSettings.x_chat_customisations_enabled,
                username: this.currentUser?.username,
              });
            }
          }
      );

      api.modifyClass(
        "component:chat-channel-sidebar-context-notification-submenu",
        (Superclass) =>
          class extends Superclass {
            @service currentUser;
            @service siteSettings;

            get notificationLevelOptions() {
              return buildSidebarNotificationLevelOptions({
                notificationLevelOptions: super.notificationLevelOptions,
                enabled: this.siteSettings.x_chat_customisations_enabled,
                username: this.currentUser?.username,
              });
            }
          }
      );

      api.modifyClass(
        "component:chat/message-creator/new-group",
        (Superclass) =>
          class extends Superclass {
            @service currentUser;

            get maxMembers() {
              return effectiveMaxMembers({
                currentUser: this.currentUser,
                maxMembers: super.maxMembers,
                membersCount: this.membersCount,
              });
            }
          }
      );

      api.modifyClass(
        "component:chat/message-creator/add-members",
        (Superclass) =>
          class extends Superclass {
            @service currentUser;

            get maxMembers() {
              return effectiveMaxMembers({
                currentUser: this.currentUser,
                maxMembers: super.maxMembers,
                membersCount: this.membersCount,
              });
            }
          }
      );

      api.modifyClass(
        "component:chat/message-creator/group",
        (Superclass) =>
          class extends Superclass {
            get isDisabled() {
              if (this.currentUser?.staff) {
                return false;
              }

              return super.isDisabled();
            }
          }
      );

      api.modifyClass(
        "component:chat/message-creator/members-selector",
        (Superclass) =>
          class extends Superclass {
            @service currentUser;

            @action
            selectChatable(chatable) {
              if (!this.currentUser?.staff) {
                return super.selectChatable(chatable);
              }

              if (
                !chatable.enabled &&
                !canStaffBypassGroupLimit({
                  currentUser: this.currentUser,
                  chatable,
                })
              ) {
                return;
              }

              if (this.highlightedMemberIds.includes(chatable.model.id)) {
                this.unselectMember(chatable);
              } else {
                this.args.onChange?.([...this.args.members, chatable]);
                this.highlightedChatable = this.items[0];
              }

              this.filter = "";
              this.focusFilterAction?.();
              this.highlightedMember = null;
            }
          }
      );

      api.modifyClass(
        "component:chat/message-creator/search",
        (Superclass) =>
          class extends Superclass {
            @service currentUser;

            @action
            async selectChatable(item) {
              if (
                !this.currentUser?.staff ||
                item.type !== "group" ||
                item.enabled
              ) {
                return super.selectChatable(item);
              }

              this.args.onChangeMode(MODES.new_group, [item]);
            }
          }
      );
        "component:chat/routes/channel-info-members",
        (Superclass) =>
          class extends Superclass {
            get canAddMembers() {
              return (
                super.canAddMembers ||
                (this.currentUser?.staff && this.args.channel.isCategoryChannel)
              );
            }
          }
      );
    });
  },
};
