module Helper
  class ValidatePostcodeHelper
    def validate_postcode(postcode)
      if postcode.length < 4
        postcode
      else
        postcode = postcode.insert(-4, " ") if postcode[-4] != " "
      end

      postcode.upcase
    end
  end
end
