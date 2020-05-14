class AddressSearchGatewayFake
  def initialize
    @addresses = []
  end

  def search_by_rrn(rrn)
    filtered_results =
      @addresses.filter do |address|
        address[:building_reference_number] == "RRN-#{rrn}"
      end

    filtered_results.map { |address| Domain::Address.new(address) }
  end

  def add(address)
    @addresses << address
  end
end
