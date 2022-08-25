module UseCase
  class ImportGreenDealFuelPrice
    class NoDataException < StandardError; end

    def initialize(green_deal_gateway)
      @green_deal_gateway = green_deal_gateway
    end

    def execute
      begin
        price_data = @green_deal_gateway.get_data
      rescue StandardError
        raise NoDataException
      end

      raise NoDataException unless price_data.is_a?(Array)
      raise NoDataException if price_data.empty?

      @green_deal_gateway.bulk_insert(price_data)
    end
  end
end
