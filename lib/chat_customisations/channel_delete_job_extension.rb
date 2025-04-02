# frozen_string_literal: true
module ChatCustomisations
  module ChannelDeleteJobExtension
    def execute(args = {})
      name = args[:channel_name]
      super
      if name
        group = Group.find_by(name: name)
        category = Category.find_by(name: name)
        if group
          GroupUser.where(group_id: group.id).destroy_all
          group.destroy
        end
        if category
          CategoryGroup.where(category_id: category.id).destroy_all
          Topic.where(category_id: category.id).destroy_all
          category.destroy
        end
      end
    end
  end
end
