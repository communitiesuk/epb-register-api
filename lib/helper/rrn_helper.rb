require "digest"

module Helper
  class RrnHelper
    class RrnNotValid < StandardError
    end
    VALID_RRN = "^(\\d{4}-){4}\\d{4}$".freeze

    def self.normalise_rrn_format(rrn)
      # Strip surrounding whitespace
      rrn = rrn.strip

      # Remove all hyphens
      rrn = rrn.tr("-", "")
      raise RrnNotValid unless rrn.length == 20

      # Add a hyphen every four characters to give desired RRN format
      rrn = rrn.scan(/.{1,4}/).join("-")
      raise RrnNotValid unless Regexp.new(VALID_RRN).match(rrn)

      rrn
    end

    def self.hash_rrn(rrn)
      rrn_array = rrn.split("-")
      rrn_array.unshift(rrn_array.last)
      rrn_array << rrn_array[1]
      Digest::SHA256.hexdigest rrn_array.join("-")
    end
  end
end
