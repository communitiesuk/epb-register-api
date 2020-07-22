module Helper
  class RrnHelper
    class RrnNotValid < StandardError; end
    VALID_RRN = "^(\\d{4}-){4}\\d{4}$".freeze

    def self.normalise_rrn_format(rrn)
      # Strip surrounding whitespace
      rrn = rrn.strip

      # Remove all hyphens
      rrn = rrn.tr('-','')
      unless rrn.length == 20
        raise RrnNotValid
      end

      # Add a hyphen every four characters to give desired RRN format
      rrn = rrn.scan(/.{1,4}/).join('-')
      unless Regexp.new(VALID_RRN).match(rrn)
        raise RrnNotValid
      end

      return rrn
    end
  end
end
