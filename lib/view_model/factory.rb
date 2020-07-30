module ViewModel
  class Factory

    TYPES_OF_CEPC = ["CEPC-8.0.0"]
    def create(xml, assessment_type)
      if TYPES_OF_CEPC.include? assessment_type
        Cepc.new
      end
    end
  end
end
