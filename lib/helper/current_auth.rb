# frozen_string_literal: true

require "active_support/current_attributes"

module Helper
  class CurrentAuth < ActiveSupport::CurrentAttributes
    attribute :auth

    def self.as_json(*)
      { auth_token: auth }
    end
  end
end
