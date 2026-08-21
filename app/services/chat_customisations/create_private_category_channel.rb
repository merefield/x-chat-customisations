# frozen_string_literal: true

module ChatCustomisations
  class CreatePrivateCategoryChannel
    include Service::Base

    params do
      attribute :name, :string
      attribute :description, :string
      attribute :slug, :string
      attribute :auto_join_users, :boolean, default: false
      attribute :threading_enabled, :boolean, default: false
      attribute :emoji, :string

      before_validation do
        self.auto_join_users = auto_join_users.presence || false
        self.threading_enabled = threading_enabled.presence || false
      end

      validates :name, presence: true, length: { maximum: SiteSetting.max_topic_title_length }

      def group_name
        name&.parameterize(separator: "_")
      end
    end

    policy :public_channels_enabled
    policy :can_create_channel
    policy :backing_records_do_not_exist

    transaction do
      model :category, :create_backing_category
      model :group, :create_backing_group
      step :clear_default_category_permissions
      model :category_group, :create_category_group
      model :group_user, :create_group_user
      model :channel, :create_channel
      model :membership, :create_membership
    end

    step :auto_join_users_if_needed

    private

    def public_channels_enabled
      SiteSetting.enable_public_channels
    end

    def can_create_channel(guardian:)
      guardian.can_create_chat_channel?
    end

    def backing_records_do_not_exist(params:)
      !Category.exists?(name: params.name) && !Group.exists?(name: params.group_name)
    end

    def create_backing_category(params:, guardian:)
      Category.create(name: params.name, user_id: guardian.user.id, read_restricted: true)
    end

    def create_backing_group(params:)
      Group.create(name: params.group_name)
    end

    def clear_default_category_permissions(category:)
      CategoryGroup.where(category_id: category.id).destroy_all
    end

    def create_category_group(category:, group:)
      CategoryGroup.create(
        category_id: category.id,
        group_id: group.id,
        permission_type: CategoryGroup.permission_types[:full],
      )
    end

    def create_group_user(group:, guardian:)
      GroupUser.create(group_id: group.id, user_id: guardian.user.id, owner: true)
    end

    def create_channel(category:, params:)
      category.create_chat_channel(
        user_count: 1,
        **params.slice(:name, :slug, :description, :auto_join_users, :threading_enabled, :emoji),
      )
    end

    def create_membership(channel:, guardian:)
      channel.user_chat_channel_memberships.create(user: guardian.user, following: true)
    end

    def auto_join_users_if_needed(channel:)
      Chat::AutoJoinChannels.call(params: { channel_id: channel.id }) if channel.auto_join_users?
    end
  end
end
