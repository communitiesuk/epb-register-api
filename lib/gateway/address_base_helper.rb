require "namecase"

module Gateway
  module AddressBaseHelper
    def self.title_case_line(address_line)
      return nil if address_line.nil?

      return address_line if address_line.upcase != address_line

      NameCase(address_line).split.map(&:upcase_first).join(" ")
    end

    def self.title_case_address(address)
      address.map { |k, v| k.to_s.include?("line") ? [k, title_case_line(v)] : [k, v] }.to_h
    end
  end
end
