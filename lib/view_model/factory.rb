module ViewModel
  class Factory
    TYPES_OF_CEPC = %w[CEPC-8.0.0].freeze
    def create(xml, assessment_type)
      ViewModel::Cepc::CepcWrapper.new(xml, assessment_type) if TYPES_OF_CEPC.include? assessment_type
    end
  end
end
