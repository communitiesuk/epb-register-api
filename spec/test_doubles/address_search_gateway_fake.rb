class AddressSearchGatewayFake
  def initialize
    @addresses = []
  end

  def search_by_postcode(postcode, building_name_number = nil)
    filtered_results =
      @addresses.filter { |address| address[:postcode] == postcode }

    if building_name_number
      filtered_results =
        filtered_results.filter do |address|
          address[:line1].include? building_name_number
        end
    end

    filtered_results.map { |address| Domain::Address.new(address) }
  end

  def search_by_rrn(rrn)
    filtered_results =
      @addresses.filter do |address|
        address[:building_reference_number] == "RRN-#{rrn}"
      end

    filtered_results.map { |address| Domain::Address.new(address) }
  end

  def search_by_street_and_town(street, town)
    filtered_results = @addresses.filter { |address| address[:town] == town }

    filtered_results =
      filtered_results.filter { |address| address[:line1].include? street }

    filtered_results.map { |address| Domain::Address.new(address) }
  end

  def add(address)
    @addresses << address
  end
end
