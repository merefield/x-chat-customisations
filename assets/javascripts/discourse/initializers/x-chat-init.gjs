import { withPluginApi } from "discourse/lib/plugin-api";
import { tracked } from "@glimmer/tracking";
import Category from "discourse/models/category";
import { service } from "@ember/service";

const PLUGIN_ID = "x-chat-customisations";
const MIN_HEIGHT_TIMELINE = 325;

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
    });
  },
};