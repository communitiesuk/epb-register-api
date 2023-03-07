# frozen_string_literal: true

module Helper
  class Platform
    ##
    # Determines whether or not this application is currently running within GOV.UK PaaS
    def self.is_paas?
      !ENV["VCAP_SERVICES"].nil?
    end
  end
end
