# frozen_string_literal: true

module ChatCustomisations
  module AddUsersToChannelContractExtension
    def self.remove_usernames_length_validator!
      contract = Chat::AddUsersToChannel::Contract

      contract
        .validators_on(:usernames)
        .select do |validator|
          validator.is_a?(ActiveModel::Validations::LengthValidator) &&
            validator.options.key?(:maximum)
        end
        .each do |validator|
          contract._validators[:usernames].delete(validator)
          contract.skip_callback(:validate, :before, validator)
        end
    end
  end
end
