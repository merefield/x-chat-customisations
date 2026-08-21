# frozen_string_literal: true

module ChatCustomisations
  module RemoveUserFromChannelExtension
    def remove(channel:, target_user:)
      super

      return if !channel.category_channel? || !channel.chatable.read_restricted

      CategoryGroup.find_by(category_id: channel.chatable.id)&.group&.users&.destroy(target_user)
    end
  end
end
