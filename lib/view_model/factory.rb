module ViewModel
  class Factory
    TYPES_OF_CEPC = %w[CEPC-8.0.0].freeze
    def create(_xml, assessment_type)
      ViewModel::Cepc::CepcWrapper.new if TYPES_OF_CEPC.include? assessment_type
    end
  end
end
