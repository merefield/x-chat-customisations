# frozen_string_literal: true

module ChatCustomisations
  module ChannelsMembershipsControllerExtension
    def create
      Chat::AddUsersToChannel.call(service_params) do
        on_success do |channel:|
          render(json: success_json.merge(memberships_count: channel.user_count))
        end
        on_failure { render(json: failed_json, status: :unprocessable_entity) }
        on_failed_policy(:can_add_users_to_channel) do
          render_json_error(I18n.t("chat.errors.users_cant_be_added_to_channel"))
        end
        on_failed_policy(:actor_allows_dms) do
          render_json_error(I18n.t("chat.errors.actor_disallowed_dms"))
        end
        on_failed_policy(:targets_allow_dms_from_user) { |policy| render_json_error(policy.reason) }
        on_failed_policy(:satisfies_dms_max_users_limit) do |policy|
          render_json_dump({ error: policy.reason }, status: 400)
        end
        on_failed_contract do |contract|
          render(
            json: failed_json.merge(errors: contract.errors.full_messages),
            status: :bad_request,
          )
        end
      end
    end

    def destroy
      Chat::RemoveUserFromChannel.call(service_params) do
        on_success do |channel:|
          render(json: success_json.merge(memberships_count: channel.user_count))
        end
        on_failure { render(json: failed_json, status: :unprocessable_entity) }
        on_model_not_found(:channel) { raise Discourse::NotFound }
        on_model_not_found(:target_user) { raise Discourse::NotFound }
        on_failed_policy(:can_remove_users_from_channel) do
          render_json_error(I18n.t("chat.errors.user_cant_be_removed_from_channel"), status: 403)
        end
        on_failed_contract do |contract|
          render(
            json: failed_json.merge(errors: contract.errors.full_messages),
            status: :bad_request,
          )
        end
      end
    end
  end
end
