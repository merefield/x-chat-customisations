// TODO: Harmonise plugin lint dependencies with the target Discourse runtime.
// eslint-disable-next-line
import DBreadcrumbsItem from "discourse/components/d-breadcrumbs-item";
// eslint-disable-next-line
import DPageSubheader from "discourse/components/d-page-subheader";
import { i18n } from "discourse-i18n";
import XChatDefaultChannelForm from "discourse/plugins/x-chat-customisations/admin/components/x-chat-default-channel-form";

export default <template>
  <DBreadcrumbsItem
    @path="/admin/plugins/chat/default-channel"
    @label={{i18n "x_chat_customisations.admin.default_channel.title"}}
  />

  <div class="x-chat-default-channel admin-detail">
    <DPageSubheader
      @titleLabel={{i18n "x_chat_customisations.admin.default_channel.title"}}
      @descriptionLabel={{i18n
        "x_chat_customisations.admin.default_channel.description"
      }}
    />

    <XChatDefaultChannelForm @model={{@controller.model}} />
  </div>
</template>
