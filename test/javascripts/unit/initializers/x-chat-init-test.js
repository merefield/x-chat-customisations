import { module, test } from "qunit";
import {
  buildNotificationLevels,
  effectiveMaxMembers,
  replaceWithDefaultDesktopChatChannel,
} from "discourse/plugins/x-chat-customisations/discourse/initializers/x-chat-init";

module("X Chat Customisations | Unit | Initializer | x-chat-init", function () {
  test("it relabels mention and inserts explicit mention before always when enabled", function (assert) {
    const notificationLevels = [
      { name: "Never", value: "never" },
      { name: "Only mentions", value: "mention" },
      { name: "Always", value: "always" },
      { name: "Explicit mention", value: "explicit_mention" },
    ];

    const result = buildNotificationLevels({
      notificationLevels,
      enabled: true,
      username: "robert",
    });

    assert.deepEqual(
      result.map((level) => level.value),
      ["never", "mention", "explicit_mention", "always"]
    );
    assert.strictEqual(
      result.find((level) => level.value === "mention").name,
      "My Mentions + @all Posts"
    );
    assert.strictEqual(
      result.find((level) => level.value === "explicit_mention").name,
      "Only For My Mentions (@robert)"
    );
  });

  test("it strips explicit mention and leaves core labels untouched when disabled", function (assert) {
    const notificationLevels = [
      { name: "Never", value: "never" },
      { name: "Only mentions", value: "mention" },
      { name: "Explicit mention", value: "explicit_mention" },
      { name: "Always", value: "always" },
    ];

    const result = buildNotificationLevels({
      notificationLevels,
      enabled: false,
      username: "robert",
    });

    assert.deepEqual(
      result.map((level) => level.value),
      ["never", "mention", "always"]
    );
    assert.strictEqual(
      result.find((level) => level.value === "mention").name,
      "Only mentions"
    );
  });

  test("it reports an infinite direct message member limit for staff", function (assert) {
    assert.strictEqual(
      effectiveMaxMembers({
        currentUser: { staff: true },
        maxMembers: 3,
      }),
      Infinity
    );
  });

  test("it reports an infinite direct message member limit when the setting is zero", function (assert) {
    assert.strictEqual(
      effectiveMaxMembers({
        currentUser: { staff: false },
        maxMembers: 0,
      }),
      Infinity
    );
  });

  test("it preserves the configured direct message member limit otherwise", function (assert) {
    assert.strictEqual(
      effectiveMaxMembers({
        currentUser: { staff: false },
        maxMembers: 3,
      }),
      3
    );
  });

  test("it redirects desktop Chat entry to the configured default channel", async function (assert) {
    const channel = { routeModels: ["general", 2] };
    const route = {
      site: { desktopView: true },
      siteSettings: {
        x_chat_customisations_default_chat_channel_id: 2,
      },
      chatChannelsManager: {
        find(channelId) {
          assert.strictEqual(channelId, 2);
          return Promise.resolve(channel);
        },
      },
      router: {
        replaceWith(routeName, ...models) {
          assert.strictEqual(routeName, "chat.channel");
          assert.deepEqual(models, channel.routeModels);
        },
      },
    };

    assert.true(await replaceWithDefaultDesktopChatChannel(route));
  });

  test("it keeps core Chat routing without a desktop default channel", async function (assert) {
    const route = {
      site: { desktopView: true },
      siteSettings: {
        x_chat_customisations_default_chat_channel_id: 0,
      },
    };

    assert.false(await replaceWithDefaultDesktopChatChannel(route));
  });

  test("it keeps core Chat routing on mobile when a desktop default is configured", async function (assert) {
    const route = {
      site: { desktopView: false },
      siteSettings: {
        x_chat_customisations_default_chat_channel_id: 2,
      },
    };

    assert.false(await replaceWithDefaultDesktopChatChannel(route));
  });
});
