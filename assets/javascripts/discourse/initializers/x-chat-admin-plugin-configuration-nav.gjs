import { withPluginApi } from "discourse/lib/plugin-api";

const CHAT_PLUGIN_ID = "chat";

export default {
  name: "x-chat-admin-plugin-configuration-nav",

  initialize(container) {
    const currentUser = container.lookup("service:current-user");
    if (!currentUser?.admin) {
      return;
    }

    withPluginApi((api) => {
      api.addAdminPluginConfigurationNav(CHAT_PLUGIN_ID, [
        {
          label: "chat.incoming_webhooks.title",
          route: "adminPlugins.show.discourse-chat-incoming-webhooks",
        },
        {
          label: "x_chat_customisations.admin.default_channel.title",
          route: "adminPlugins.show.x-chat-customisations-default-channel",
        },
      ]);
    });
  },
};
