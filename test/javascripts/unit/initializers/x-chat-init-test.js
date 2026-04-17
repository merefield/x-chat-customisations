import { module, test } from "qunit";
import { buildNotificationLevels } from "discourse/plugins/x-chat-customisations/discourse/initializers/x-chat-init";

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
      "For Mentions (@robert) & Broadcasts (@all)"
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
});
