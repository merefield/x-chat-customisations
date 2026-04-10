import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { withPluginApi } from "discourse/lib/plugin-api";
import Category from "discourse/models/category";
import { i18n } from "discourse-i18n";

const PLUGIN_ID = "x-chat-customisations";
const A_LOT_OF_MEMBERS = 10000; // Define a constant for a large number of members

export default {
  name: "x-chat-init",
  pluginId: PLUGIN_ID,
  initialize() {
    withPluginApi("0.8.40", (api) => {
      api.modifyClass(
        "component:chat/modal/create-channel",
        (Superclass) =>
          class extends Superclass {
            @service siteSettings;

            @tracked
            categoryId =
              this.siteSettings
                .x_chat_customisations_channel_creation_default_category_id; // property already exists, but let's add a default value.
            @tracked category = Category.findById(this.categoryId);
            @tracked threadingEnabled = true;
            @tracked autoJoinUsers = false;
          }
      );

      api.modifyClass(
        "component:chat/message-creator/add-members",
        (Superclass) =>
          class extends Superclass {
            @service currentUser;

            get maxMembers() {
              if (
                this.currentUser?.staff ||
                this.siteSettings.chat_max_direct_message_users === 0
              ) {
                return Infinity;
              }
              return this.siteSettings.chat_max_direct_message_users;
            }
          }
      );

      api.modifyClass(
        "component:chat/message-creator/group",
        (Superclass) =>
          class extends Superclass {
            @service currentUser;

            get isDisabled() {
              if (this.currentUser?.staff) {
                return false;
              }

              return super.isDisabled();

              // if (!this.args.membersCount) {
              //   return !this.args.item.enabled;
              // }

              // return (
              //   this.args.membersCount + this.args.item.model.chat_enabled_user_count >
              //   this.siteSettings.chat_max_direct_message_users
              // );
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
              if (!chatable.enabled) {
                return;
              }

              const chatableMembers =
                chatable.type === "group"
                  ? chatable.model.chat_enabled_user_count
                  : 1;

              if (
                this.args.membersCount + chatableMembers >
                  this.siteSettings.chat_max_direct_message_users &&
                !this.currentUser?.staff
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
        "component:chat/message-creator/new-group",
        (Superclass) =>
          class extends Superclass {
            @service currentUser;

            get maxMembers() {
              if (
                this.currentUser?.staff ||
                this.siteSettings.chat_max_direct_message_users === 0
              ) {
                return A_LOT_OF_MEMBERS; // Use a constant or a large number to represent "infinity"
              }
              return this.siteSettings.chat_max_direct_message_users;
            }
          }
      );

      api.modifyClass(
        "component:chat/routes/channel-info-settings",
        (Superclass) =>
          class extends Superclass {
            @service currentUser;

            get notificationLevels() {
              if (!this.siteSettings.x_chat_customisations_enabled) {
                return [
                  {
                    name: i18n("chat.notification_levels.never"),
                    value: "never",
                  },
                  {
                    name: i18n("chat.notification_levels.mention"),
                    value: "mention",
                  },
                  {
                    name: i18n("chat.notification_levels.always"),
                    value: "always",
                  },
                ];
              }

              return [
                {
                  name: i18n("chat.notification_levels.never"),
                  value: "never",
                },
                {
                  name: i18n(
                    "x_chat_customisations.notification_levels.mention",
                    {
                      username: this.currentUser?.username,
                    }
                  ),
                  value: "mention",
                },
                {
                  name: i18n(
                    "x_chat_customisations.notification_levels.explicit_mention",
                    {
                      username: this.currentUser?.username,
                    }
                  ),
                  value: "explicit_mention",
                },
                {
                  name: i18n("chat.notification_levels.always"),
                  value: "always",
                },
              ];
            }
          }
      );

      api.modifyClass(
        "component:chat/routes/channel-info-members",
        (Superclass) =>
          class extends Superclass {
            @service dialog;
            @service siteSettings;
            @service toasts;

            get canAddMembers() {
              if (
                this.siteSettings.x_chat_customisations_enabled &&
                this.currentUser?.staff
              ) {
                return true;
              }

              return super.canAddMembers;
            }

            canRemoveMember(user) {
              if (!this.siteSettings.x_chat_customisations_enabled) {
                return super.canRemoveMember(user);
              }

              return (
                user.id !== this.currentUser.id &&
                (this.currentUser?.staff || this.args.channel.canRemoveMembers)
              );
            }

            @action
            removeMember(user) {
              if (
                !this.siteSettings.x_chat_customisations_enabled ||
                !this.currentUser?.staff ||
                this.args.channel.canRemoveMembers
              ) {
                return super.removeMember(user);
              }

              this.dialog.confirm({
                message: i18n(
                  "x_chat_customisations.members_view.remove_member_prompt",
                  {
                    username: user.username,
                  }
                ),
                didConfirm: async () => {
                  try {
                    await ajax(
                      `/chat/api/channels/${this.args.channel.id}/memberships/${user.username_lower}`,
                      {
                        type: "DELETE",
                      }
                    );

                    this.toasts.success({
                      data: {
                        message: i18n(
                          "x_chat_customisations.members_view.remove_member_success",
                          {
                            username: user.username,
                          }
                        ),
                      },
                      duration: 2000,
                    });
                    this.updatedAt = Date.now();
                    this.load();
                  } catch (error) {
                    popupAjaxError(error);
                  }
                },
              });
            }
          }
      );
    });
  },
};
