# frozen_string_literal: true
module ChatCustomisations
  module ApiChannelControllerExtension
    def create
      return super unless private_channel_bootstrap_requested?

      channel_params =
        params.require(:channel).permit(
          :chatable_id,
          :name,
          :slug,
          :description,
          :auto_join_users,
          :threading_enabled,
          :emoji,
        )

      ChatCustomisations::CreatePrivateCategoryChannel.call(
        service_params.deep_merge(params: channel_params.except(:chatable_id).to_h),
      ) do
        on_success do |channel:, membership:|
          render_serialized(channel, Chat::ChannelSerializer, root: "channel", membership:)
        end
        on_failed_policy(:can_create_channel) { raise Discourse::InvalidAccess }
        on_failed_policy(:backing_records_do_not_exist) do
          raise Discourse::InvalidParameters.new(
                  "A Category or Group with the name #{channel_params[:name]} already exists, choose a different name",
                )
        end
        on_model_errors(:category) do |model|
          render_json_error(model, type: :record_invalid, status: 422)
        end
        on_model_errors(:group) do |model|
          render_json_error(model, type: :record_invalid, status: 422)
        end
        on_model_errors(:category_group) do |model|
          render_json_error(model, type: :record_invalid, status: 422)
        end
        on_model_errors(:group_user) do |model|
          render_json_error(model, type: :record_invalid, status: 422)
        end
        on_model_errors(:channel) do |model|
          render_json_error(model, type: :record_invalid, status: 422)
        end
        on_model_errors(:membership) do |model|
          render_json_error(model, type: :record_invalid, status: 422)
        end
        on_failure { render(json: failed_json, status: :unprocessable_entity) }
        on_failed_contract do |contract|
          render(
            json: failed_json.merge(errors: contract.errors.full_messages),
            status: :bad_request,
          )
        end
      end
    end

    private

    def private_channel_bootstrap_requested?
      params.dig(:channel, :chatable_id).to_s ==
        SiteSetting.x_chat_customisations_private_chat_dummy_category_id.to_s &&
        params[:channel][:name].present?
    end
  end
end
