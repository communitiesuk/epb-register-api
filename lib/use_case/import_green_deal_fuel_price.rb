module UseCase
  class ImportGreenDealFuelPrice
    class NoDataException < StandardError; end

    def initialize(green_deal_gateway)
      @green_deal_gateway = green_deal_gateway
    end

    def execute
      begin
        price_data = get_data
      rescue StandardError
        raise NoDataException
      end

      raise NoDataException unless price_data.is_a?(Array)
      raise NoDataException if price_data.empty?

      @green_deal_gateway.bulk_insert(price_data)
    end

  private

    def get_data
      string_response = Net::HTTP.get URI "http://www.boilers.org.uk/data1/pcdf2012.dat"
      string_response.scan(/^\d,\d+,\d+,\d+\.\d+,\d{4}\/\S+\/\d+ \d{2}:\d{2}/mi)
    end
  end
end
