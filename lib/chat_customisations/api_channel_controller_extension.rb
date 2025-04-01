#frozen_string_literal: true
module ChatCustomisations
  module ApiChannelControllerExtension
    def create
      if (params.dig(:channel, :chatable_id)&.== SiteSetting.x_chat_customisations_private_chat_dummy_category_id.to_s) && params[:channel][:name].present?
        name = params[:channel][:name]
        if Category.exists?(name: name) || Group.exists?(name: name)
            raise Discourse::InvalidParameters.new("A Category or Group with the name #{name} already exists, choose a different name")
        end
        category = Category.new(name: name, user_id: current_user.id)
        category.save!
        params[:channel][:chatable_id] = category.id
        group = Group.new(name: name)
        group.save!
        CategoryGroup.where(category_id: category.id).destroy_all
        cg = CategoryGroup.create!(category_id: category.id, group_id: group.id, permission_type: CategoryGroup.permission_types[:full]) 
        gu = GroupUser.create!(group_id: group.id, user_id: current_user.id)
      end
      super
    end
  end
end
