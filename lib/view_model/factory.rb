module ViewModel
  class Factory
    TYPES_OF_CEPC = %w[CEPC-8.0.0].freeze
    def create(xml, schema_type)
      if TYPES_OF_CEPC.include? schema_type
        ViewModel::Cepc::CepcWrapper.new(xml, schema_type)
      end
    end
  end
end
