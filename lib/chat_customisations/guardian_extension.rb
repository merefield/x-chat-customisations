# frozen_string_literal: true

module ChatCustomisations
  module GuardianExtension
    def can_remove_members?(channel)
      return true if is_staff? && (channel.category_channel? || channel.direct_message_group?)

      super
    end
  end
end
