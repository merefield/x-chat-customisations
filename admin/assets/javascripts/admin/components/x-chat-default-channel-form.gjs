import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import ChatChannelChooser from "discourse/plugins/chat/discourse/components/chat-channel-chooser";

export default class XChatDefaultChannelForm extends Component {
  @service toasts;

  @tracked savedDefaultChatChannelId = null;

  get defaultChatChannelId() {
    return (
      this.savedDefaultChatChannelId ?? this.args.model.defaultChatChannelId
    );
  }

  get formData() {
    return {
      chat_channel_id: this.defaultChatChannelId,
    };
  }

  @action
  async selectDefaultChannel(setData, chatChannelId) {
    setData("chat_channel_id", chatChannelId);
    await this.saveDefaultChannel(chatChannelId);
  }

  @action
  async saveDefaultChannel(chatChannelId) {
    try {
      const result = await ajax(
        "/admin/plugins/x-chat-customisations/default-channel",
        {
          type: "PUT",
          data: {
            chat_channel_id: chatChannelId || 0,
          },
        }
      );

      this.savedDefaultChatChannelId = result.default_chat_channel_id;

      this.toasts.success({
        duration: "short",
        data: {
          message: i18n("x_chat_customisations.admin.default_channel.saved"),
        },
      });
    } catch (err) {
      popupAjaxError(err);
    }
  }

  <template>
    <div class="x-chat-default-channel-form">
      <Form @data={{this.formData}} as |form|>
        <form.Field
          @name="chat_channel_id"
          @title={{i18n "x_chat_customisations.admin.default_channel.channel"}}
          @type="custom"
          as |field|
        >
          <field.Control>
            <ChatChannelChooser
              @content={{@model.chatChannels}}
              @value={{field.value}}
              @onChange={{fn this.selectDefaultChannel form.set}}
            />
          </field.Control>
        </form.Field>
      </Form>

      <DButton
        @label="x_chat_customisations.admin.default_channel.none"
        @action={{fn this.saveDefaultChannel 0}}
        class="btn-default"
      />
    </div>
  </template>
}
