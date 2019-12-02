module UseCase
  class AddAssessor

    class SchemeNotFoundException < Exception

    end

    def initialize(gateway)
      @gateway = gateway
    end

    def execute(scheme_id)
      scheme_exists = @gateway.all.map do |scheme|
        scheme[:scheme_id].to_s
      end.include?(scheme_id)

      if scheme_exists
      else
        raise SchemeNotFoundException
      end
    end
  end
end
