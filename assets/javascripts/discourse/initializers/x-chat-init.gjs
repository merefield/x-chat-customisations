import { withPluginApi } from "discourse/lib/plugin-api";
import { tracked } from "@glimmer/tracking";
import Category from "discourse/models/category";
import { service } from "@ember/service";

const PLUGIN_ID = "x-chat-customisations";
const MIN_HEIGHT_TIMELINE = 325;
const A_LOT_OF_MEMBERS = 10000; // Define a constant for a large number of members

export default {
  name: "x-chat-init",
  initialize(application) {
    withPluginApi("0.8.40", (api) => {
      api.modifyClass("component:chat/modal/create-channel", 
        (Superclass) =>
            class extends Superclass {
              @service siteSettings;

              @tracked categoryId = this.siteSettings.x_chat_customisations_channel_creation_default_category_id; // property already exists, but let's add a default value.
              @tracked category = Category.findById(this.categoryId);
              @tracked threadingEnabled = true;
              @tracked autoJoinUsers = false;
            }
      );

      api.modifyClass("component:chat/message-creator/add-members", 
        (Superclass) =>
            class extends Superclass {
              @service currentUser;

              get maxMembers() {
                  if (this.currentUser?.staff || this.siteSettings.chat_max_direct_message_users === 0) {
                      return Infinity;
                  }
                  return this.siteSettings.chat_max_direct_message_users;
              }
            }
      );

            api.modifyClass("component:chat/message-creator/group", 
        (Superclass) =>
            class extends Superclass {
              get isDisabled() {
                if (this.currentUser?.staff) {
                  return false;
                }

                console.log("Yeah man!!!  ");

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

            api.modifyClass("component:chat/message-creator/members-selector", 
        (Superclass) =>
            class extends Superclass {
              @service currentUser;

              @action
              selectChatable(chatable) {
                if (!chatable.enabled) {
                  return;
                }

                const chatableMembers =
                  chatable.type === "group" ? chatable.model.chat_enabled_user_count : 1;

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


            api.modifyClass("component:chat/message-creator/new-group", 
        (Superclass) =>
            class extends Superclass {
              @service currentUser;

              get maxMembers() {
                  if (this.currentUser?.staff || this.siteSettings.chat_max_direct_message_users === 0) {
                      return A_LOT_OF_MEMBERS; // Use a constant or a large number to represent "infinity"
                  }
                  return this.siteSettings.chat_max_direct_message_users;
              }

              <template>
                <MembersCount
                  @count={{this.membersCount}}
                  @max={{this.maxMembers}}
                />
              </template>
            }
      );
    });
  },
};