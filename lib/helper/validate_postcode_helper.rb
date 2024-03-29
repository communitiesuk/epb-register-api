module Helper
  class ValidatePostcodeHelper
    def self.format_postcode(postcode)
      postcode.gsub!(/[[:space:]]/, "")
      postcode.insert(-4, " ") unless postcode.length < 3
      postcode.upcase
    end

    def self.valid_postcode?(postcode)
      return false if postcode.length < 4

      Regexp.new(Helper::RegexHelper::POSTCODE, Regexp::IGNORECASE)
            .match?(format_postcode(postcode))
    end
  end
end
