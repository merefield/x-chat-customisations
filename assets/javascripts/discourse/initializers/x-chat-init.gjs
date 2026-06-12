import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
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
      `chat-channel-sidebar-link-menu__notification-level-${level.value.replaceAll(
        "_",
        "-"
      )}`,
  }));
}

export function effectiveMaxMembers({ currentUser, maxMembers }) {
  if (currentUser?.staff || maxMembers === 0) {
    return Infinity;
  }

  return maxMembers;
}

const POSTING_MODES = [
  {
    name: i18n("x_chat_customisations.posting_modes.anyone"),
    value: "anyone",
  },
  {
    name: i18n("x_chat_customisations.posting_modes.staff_only"),
    value: "staff_only",
  },
  {
    name: i18n(
      "x_chat_customisations.posting_modes.staff_only_replies_allowed"
    ),
    value: "staff_only_replies_allowed",
  },
];

export function canStaffBypassGroupLimit({ currentUser, chatable }) {
  return currentUser?.staff && chatable?.type === "group";
}

export function defaultBrowseRoute() {
  return "chat.browse.all";
}

export async function replaceWithDefaultDesktopChatChannel(route) {
  const defaultChannelId = Number(
    route.siteSettings?.x_chat_customisations_default_chat_channel_id
  );

  if (!route.site?.desktopView || !defaultChannelId) {
    return false;
  }

  try {
    const channel = await route.chatChannelsManager.find(defaultChannelId);

    if (channel?.routeModels) {
      route.router.replaceWith("chat.channel", ...channel.routeModels);
      return true;
    }
  } catch {
    // Fall back to core Chat routing when the configured channel is unavailable.
  }

  return false;
}

export default {
  name: "x-chat-init",
  initialize() {
    withPluginApi((api) => {
      api.modifyClass(
        "route:chat.index",
        (Superclass) =>
          class extends Superclass {
            async redirect() {
              if (await replaceWithDefaultDesktopChatChannel(this)) {
                return;
              }

              return super.redirect(...arguments);
            }
          }
      );

      api.modifyClass(
        "route:chat.channels",
        (Superclass) =>
          class extends Superclass {
            @service siteSettings;

            async beforeModel() {
              if (await replaceWithDefaultDesktopChatChannel(this)) {
                return;
              }

              return super.beforeModel(...arguments);
            }
          }
      );

      api.modifyClass(
        "route:chat.browse.index",
        (Superclass) =>
          class extends Superclass {
            afterModel() {
              this.router.replaceWith(defaultBrowseRoute());
            }
          }
      );

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

            get shouldRenderPostingModeSection() {
              return (
                this.siteSettings.x_chat_customisations_enabled &&
                this.args.channel.isCategoryChannel &&
                this.chatGuardian.canEditChatChannel()
              );
            }

            get postingModeLabel() {
              return i18n("x_chat_customisations.posting_modes.label");
            }

            get postingModeOptions() {
              return POSTING_MODES;
            }

            get postingModeValue() {
              return this.args.channel.xChatPostingMode ?? "anyone";
            }

            @action
            async onChangePostingMode(value) {
              const previousValue = this.args.channel.xChatPostingMode;
              this.args.channel.xChatPostingMode = value;

              try {
                const result = await ajax(
                  `/chat/api/channels/${this.args.channel.id}/posting-mode`,
                  {
                    type: "PUT",
                    data: {
                      posting_mode: value,
                    },
                  }
                );
                this.args.channel.xChatPostingMode =
                  result.channel.x_chat_posting_mode;
                this.toasts.success({ data: { message: i18n("saved") } });
              } catch (error) {
                this.args.channel.xChatPostingMode = previousValue;
                popupAjaxError(error);
              }
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
              });
            }
          }
      );

      api.modifyClass(
        "component:chat/message-creator/group",
        (Superclass) =>
          class extends Superclass {
            @service currentUser;
            @service siteSettings;

            get isDisabled() {
              if (this.currentUser?.staff) {
                return false;
              }

              if (!this.args.membersCount) {
                return !this.args.item.enabled;
              }

              return (
                this.args.membersCount +
                  this.args.item.model.chat_enabled_user_count >
                this.siteSettings.chat_max_direct_message_users
              );
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

      api.modifyClass(
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
