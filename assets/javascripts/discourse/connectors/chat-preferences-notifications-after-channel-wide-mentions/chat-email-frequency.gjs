import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

const EMAIL_FREQUENCY_OPTIONS = [
  { name: i18n("chat.email_frequency.never"), value: "never" },
  { name: i18n("chat.email_frequency.when_away"), value: "when_away" },
];

export default <template>
  {{#let @outletArgs.form @outletArgs.data as |form data|}}
    <form.Field
      @title={{i18n "chat.email_frequency.title"}}
      @description={{if
        (eq data.chat_email_frequency "when_away")
        (i18n "chat.email_frequency.description")
      }}
      @name="chat_email_frequency"
      @format="large"
      @type="select"
      as |field|
    >
      <field.Control @includeNone={{false}} as |select|>
        {{#each EMAIL_FREQUENCY_OPTIONS as |option|}}
          <select.Option @value={{option.value}}>
            {{option.name}}
          </select.Option>
        {{/each}}
      </field.Control>
    </form.Field>
  {{/let}}
</template>
