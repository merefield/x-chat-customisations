# frozen_string_literal: true

module ChatCustomisations
  module MessageCookExtension
    def cook(message, opts = {})
      super(ChatCustomisations::TenantReplayOneboxPreprocessor.call(message), opts)
    end
  end
end
