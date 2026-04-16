# x-chat-customisations

This plugin works alongside a fork of the core Discourse Chat plugin in
`/home/robert/code/chat`.

The table below is the current inventory of functional changes from base
Discourse Chat. The `Chat Fork` column shows whether the behavior depends on
changes in the forked chat plugin. The `x-chat-customisations` column shows
whether the behavior depends on code in this plugin.

| Title | Description | Chat Fork | x-chat-customisations |
| --- | --- | --- | --- |
| Explicit mention notification level | Adds a fourth channel notification level, `explicit_mention`. Users on this level still receive direct `@username` mentions, but opt out of broadcast-style mention notifications such as `@all` and `@here`. This feature depends on forked chat support for the extra enum value and client-side menu options, plus plugin-side notification handling. | Yes | Yes |
| Explicit mention settings and labels | Extends the channel notification settings UI to show the custom `explicit_mention` option and relabels the normal `mention` option with username-aware wording. The sidebar notification submenu also uses plugin-specific translation keys when the customisations plugin is enabled. | Yes | Yes |
| Channel creation default category | Prefills the create-channel modal with the category configured by `x_chat_customisations_channel_creation_default_category_id`, instead of making the user start from a blank category chooser every time. | No | Yes |
| Channel creation forces threading on | Defaults `threadingEnabled` to `true` in the create-channel modal and hides the threading toggle in that flow, so channels created through this UI path are threaded without presenting threading as a choice. | No | Yes |
| Private channel bootstrap from dummy category | When a channel is created against the configured dummy private category, the plugin creates a new read-restricted category and a matching group named after the requested channel, rewrites the create request to use that new category, and makes the creator an owner of the new group. This turns one configured placeholder category into a private-channel creation mechanism. | No | Yes |
| New category channels default `allow_channel_wide_mentions` to false | Changes the default for newly created category chat channels so `allow_channel_wide_mentions` starts disabled instead of inheriting base chat's default `true`. This affects whether `@all` and `@here` are enabled immediately after channel creation. | No | Yes |
| Private channel teardown cleanup | Extends channel deletion so channels created through the private-category bootstrap flow also remove their generated group, category-group join rows, category topics, and backing category during cleanup. This keeps the custom private-channel lifecycle symmetrical on create and delete. | No | Yes |
| Add-member sync for private/read-restricted channels | When users are added to a private category-backed chat, the plugin also adds them to the backing category group so category permissions stay aligned with chat membership. The override also creates new memberships at notification level `mention` instead of core chat's `always`. | No | Yes |
| Username-based member removal API | Adds `DELETE /chat/api/channels/:channel_id/memberships/by-username/:username` for callers that identify members by username instead of user id. On private category-backed chats it also removes the user from the backing category group. This is intentionally additive rather than replacing the newer core user-id endpoint. | No | Yes |
| Chat summary suppression for `@all` mentions | Alters chat-summary email eligibility so unread broadcast mentions created only by `Chat::AllMention` do not qualify a user for a summary email. Direct mentions and other supported unread cases still qualify. This currently lives in a mailer override that should track core mailer changes closely. | No | Yes |
| Global disable for chat summary emails | Adds the site setting `x_chat_customisations_chat_summary_emails_enabled`. When disabled, queued `chat_summary` emails are skipped and recorded in `SkippedEmailLog` rather than delivered. | No | Yes |
| Enhanced email logging | Adds optional warn-level logging around `Jobs::UserEmail#send_user_email` and `#message_for_email` to help debug production email behavior. This is controlled by `x_chat_customisations_enhanced_logging`. | No | Yes |
| Explicit mention notification filtering in the mention job | Extends the mention notification job so users whose channel membership is set to `explicit_mention` do not receive notifications for `@all`, `@here`, or other non-direct identifier types, while direct mentions still produce notifications. | No | Yes |
| Search exclusion semantics for membership lookups | Overrides chatable user search so `excluded_memberships_channel_id` excludes users who are already following a channel. This differs from current core behavior and should be treated as a deliberate search customization until it is narrowed or removed. | No | Yes |
| Auto-join scheduler cadence | Re-registers `Jobs::Chat::AutoJoinUsers` to run every 10 minutes. This changes how quickly category chat channels with `auto_join_users` enabled pick up newly eligible users. | No | Yes |
| Operator rake tasks for bulk seen-state changes | Adds `x_chat:make_seen` and `x_chat:make_unseen` rake tasks that bulk-update `last_seen_at`, either on one site or across all multisite databases. These are operational utilities, not end-user chat features, but they do change how the chat environment can be administered. | No | Yes |

## Notes

- Rows marked `Yes / Yes` need coordinated maintenance across both repositories.
- Rows marked `No / Yes` can usually be evolved entirely inside this plugin.
- The chat fork also contains a small number of extension seams, such as the
  overridable `notificationLevels` getter and the `maxMembers` template hook,
  that are not listed as standalone features here because they do not change
  user-visible behavior on their own.
