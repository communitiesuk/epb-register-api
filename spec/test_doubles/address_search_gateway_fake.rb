class AddressSearchGatewayFake
  def initialize
    @addresses = []
  end

  def search_by_postcode(
    postcode, building_name_number = nil, address_type = nil
  )
    filtered_results =
      @addresses.filter { |address| address[:postcode] == postcode }

    if building_name_number
      filtered_results =
        filtered_results.filter do |address|
          if address[:line2]
            address[:line2].include?(building_name_number)
          else
            address[:line1].include?(building_name_number)
          end
        end
    end

    if address_type
      assessment_types = (%w[SAP RdSAP] if address_type == "DOMESTIC")

      filtered_results =
        filtered_results.filter do |address|
          assessment_types.include? address[:assessment_type]
        end
    end

    results_to_domain filtered_results
  end

  def search_by_rrn(rrn)
    filtered_results =
      @addresses.filter do |address|
        address[:building_reference_number] == "RRN-#{rrn}"
      end

    results_to_domain filtered_results
  end

  def search_by_street_and_town(street, town, address_type)
    filtered_results =
      @addresses.filter do |address|
        if address[:line2] == town
          true
        elsif address[:town] == town
          true
        end
      end

    filtered_results =
      filtered_results.filter do |address|
        if address[:line2] && address[:line2].include?(street)
          true
        elsif address[:line1].include? street
          true
        end
      end

    if address_type
      assessment_types = (%w[SAP RdSAP] if address_type == "DOMESTIC")

      filtered_results =
        filtered_results.filter do |address|
          assessment_types.include? address[:assessment_type]
        end
    end

    results_to_domain filtered_results
  end

  def add(address)
    @addresses << address
  end

private

  def results_to_domain(results)
    results.map do |address|
      Domain::Address.new(
        address.slice(
          :building_reference_number,
          :line1,
          :line2,
          :line3,
          :town,
          :postcode,
          :source,
          :existing_assessments,
        ),
      )
    end
  end
end
