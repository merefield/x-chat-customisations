import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";
import ChatChannel from "discourse/plugins/chat/discourse/models/chat-channel";

export default class XChatCustomisationsDefaultChannelRoute extends DiscourseRoute {
  @service currentUser;

  async model() {
    if (!this.currentUser?.admin) {
      return { chatChannels: [], defaultChatChannelId: 0 };
    }

    try {
      const model = await ajax(
        "/admin/plugins/x-chat-customisations/default-channel.json"
      );

      return {
        chatChannels: model.chat_channels.map((channel) =>
          ChatChannel.create(channel)
        ),
        defaultChatChannelId: model.default_chat_channel_id,
      };
    } catch (err) {
      popupAjaxError(err);
    }
  }

  titleToken() {
    return i18n("x_chat_customisations.admin.default_channel.title");
  }
}
