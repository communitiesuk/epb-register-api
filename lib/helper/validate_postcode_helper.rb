module Helper
  class ValidatePostcodeHelper
    class PostcodeNotValid < StandardError
    end

    def validate_postcode(postcode)
      if postcode.length < 4
        raise PostcodeNotValid
      else
        postcode.insert(-4, " ") unless postcode[-4] == " "
      end

      postcode.upcase
    end
  end
end
