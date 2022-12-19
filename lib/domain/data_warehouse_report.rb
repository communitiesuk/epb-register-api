# frozen_string_literal: true

module Domain
  class DataWarehouseReport
    def initialize(name:, data:, generated_at:)
      @name = name
      @data = data
      @generated_at = generated_at
    end

    attr_reader :name, :data, :generated_at

    def to_hash
      {
        name:,
        data:,
        generated_at:,
      }
    end
  end
end
