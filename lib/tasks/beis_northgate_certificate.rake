desc "Delete all beis certificates"

task :delete_beis_northgate_certificate do
  if ENV["STAGE"] == "production"
    raise StandardError, "I will not delete the production data"
  end
  ActiveRecord::Base.connection.execute("DELETE FROM domestic_epc_energy_improvements WHERE assessment_id LIKE '%1111-2222%'")
  ActiveRecord::Base.connection.execute("DELETE FROM assessments WHERE assessment_id LIKE '%1111-2222%'")
end

desc "Import some random certificate data"

task :generate_beis_northgate_certificate do
  if ENV["STAGE"] == "production"
    raise StandardError, "I will not seed the production db"
  end

  puts "creating assessments"

  addresses = [
    { id: "", line1: "Flat 32", line2: "11 Magpie Street", line3: "", line4: "", town: "London", postcode: "E2 0SZ" },
    { id: "", line1: "Flat 34", line2: "11 Magpie Street", line3: "", line4: "", town: "London", postcode: "E2 0SZ" },
    { id: "", line1: "Flat 68", line2: "11 Magpie Street", line3: "", line4: "", town: "London", postcode: "E2 0SX" },
    { id: "", line1: "The Dormers", line2: "Milton Mews", line3: "", line4: "", town: "London", postcode: "NW3 2UU" },
    { id: "", line1: "8 Spooky Avenue", line2: "", line3: "", line4: "", town: "London", postcode: "SW1A 2AA" },
    { id: "", line1: "9 Batey Street", line2: "", line3: "", line4: "", town: "London", postcode: "SW1A 2AA" },
    { id: "", line1: "2a Violet Crescent", line2: "", line3: "", line4: "", town: "London", postcode: "SE1 1TE" },
    { id: "", line1: "15", line2: "Thomas Lane", line3: "", line4: "", town: "London", postcode: "SW1X 7XL" },
    { id: "", line1: "First floor flat", line2: "7a Parkhill Road", line3: "", line4: "", town: "London", postcode: "W1B 5BT" },
    { id: "", line1: "1 Hamlet Building", line2: "", line3: "", line4: "", town: "Bournemouth", postcode: "BH2 5BH" },
    { id: "", line1: "Unit 23", line2: "Roweland Industrial Estate", line3: "Coast Road", line4: "", town: "Newcastle", postcode: "NE23 8WD" },
    { id: "", line1: "Flat 2", line2: "1 Alpha Road", line3: "", line4: "", town: "London", postcode: "E2 0SI" },
    { id: "", line1: "Flat 4", line2: "1 Alpha Road", line3: "", line4: "", town: "London", postcode: "E2 0SI" },
    { id: "", line1: "Flat 8", line2: "1 Alpha Road", line3: "", line4: "", town: "London", postcode: "E2 0ST" },
    { id: "", line1: "The Grove", line2: "Smithfield", line3: "", line4: "", town: "London", postcode: "N3 2UU" },
    { id: "", line1: "10 Chillder Avenue", line2: "", line3: "", line4: "", town: "Newcastle", postcode: "NE3 2AA" },
    { id: "", line1: "9 Batey Street", line2: "", line3: "", line4: "", town: "London", postcode: "SW1A 2AA" },
    { id: "", line1: "9a Violet Crescent", line2: "", line3: "", line4: "", town: "London", postcode: "SE1 1TE" },
    { id: "", line1: "47", line2: "Sara Lane", line3: "", line4: "", town: "London", postcode: "SE1X 7PE" },
    { id: "", line1: "Second floor flat", line2: "Jumphill Road", line3: "", line4: "", town: "London", postcode: "W1B 5BT" },
    { id: "", line1: "8 Hamlet Building", line2: "", line3: "", line4: "", town: "Bournemouth", postcode: "BH2 5BH" },
    { id: "", line1: "Unit 93", line2: "Roweland Industrial Estate", line3: "Coast Road", line4: "", town: "Newcastle", postcode: "NE23 8WD" },
  ]

  dwelling_type = ["end-terrace house", "terrace house", "flat", "bungalow", "mansion", "castle"]
  type_of_assessment = "RdSAP"
  lighting_cost_current = [1233, 3445, 4546.32, 6748, 8910, 7483, 8963]
  heating_cost_current = [7983, 2321.71, 4524, 6478, 8932, 6483.12, 32_363]
  hot_water_cost_current = [2333.25, 3445, 4546.33, 6748, 8910, 7483.92, 8963]
  lighting_cost_potential = [233, 445.62, 546, 748, 910, 483, 963]
  heating_cost_potential = [233, 445, 546.09, 748, 910.73, 483, 963.28]
  hot_water_cost_potential = [783, 231, 424, 648, 932.96, 643, 1293]
  current_space_heating_demand = [1233, 3445, 4546, 6748, 8910, 7483, 8963]
  current_water_heating_demand = [7983, 2321, 454, 648, 8932, 6483, 72_363]
  current_carbon_emission = [5.4, 4.327, 7.8, 4.5, 6.4, 4]
  potential_carbon_emission = [1.4, 0.5, 3.5, 2.1, 3.624, 1]
  impact_of_loft_insulation = [-21, -543, -764, -836, -13, -94, -35]
  impact_of_cavity_insulation = [-21, -764, -836, -13, -94, -35]
  impact_of_solid_wall_insulation = [-4, -53, -64, -99, -23, -73, -5]
  improvement_code = %w[1 2 3 4 5 6 7 8 9 10 11 12 13].shuffle
  indicative_cost = ["£448 - £463", "£30", "£82765 - £700000", "£485 - £728", "£2000 - £3,500"]
  typical_saving = [453.45, 200, 310.49, 999.99, 1000, 550.50]
  improvement_category = %w[a b c d e f]
  improvement_type = %w[minor medium major]
  energy_performance_rating_improvement = [93, 85, 75, 62, 45]
  environmental_impact_rating_improvement = [93, 85, 75, 62, 45]
  green_deal_category_code = %w[a b c d e]
  related_party_disclosure_number = [1, 2, 3, 4, 5, 6, 7]
  related_party_disclosure_text = ["No related party",
                                   "Relative of homeowner or of occupier of the property",
                                   "Residing at the property",
                                   "Financial interest in the property",
                                   "Owner or Director of the organisation dealing with the property transaction",
                                   "Employed by the professional dealing with the property transaction",
                                   "Relative of the professional dealing with the property transaction",
                                   nil,
                                   nil,
                                   nil,
                                   nil,
                                   nil,
                                   nil]
  property_summary = [
    [
      {
        "name": "walls",
        "description": "Brick wall, no insulation",
        "energy_efficiency_rating": "4",
        "environmental_efficiency_rating": "0",
      },
      {
        "name": "secondary_heating",
        "description": "None",
        "energy_efficiency_rating": "3",
        "environmental_efficiency_rating": "0",
      },
    ].to_json,
    [
      {
        "name": "main_heating",
        "description": "Room heaters, electric",
        "energy_efficiency_rating": "3",
        "environmental_efficiency_rating": "0",
      },
      {
        "name": "hot_water",
        "description": "Gas Boiler",
        "energy_efficiency_rating": "1",
        "environmental_efficiency_rating": "0",
      },
    ].to_json,
    [
      {
        "name": "window",
        "description": "Fully double glazed",
        "energy_efficiency_rating": "3",
        "environmental_efficiency_rating": "0",
      },
      {
        "name": "floor",
        "description": "Suspended, no insulation (assumed)",
        "energy_efficiency_rating": "0",
        "environmental_efficiency_rating": "0",
      },
    ].to_json,
  ]

  result = ActiveRecord::Base.connection.execute("SELECT * FROM assessors ORDER BY random() LIMIT 1000")

  result.each_with_index do |assessor, number|
    address = addresses.sample

    assessments_at_address = ActiveRecord::Base.connection.execute("SELECT assessment_id FROM assessments WHERE address_line1 = '#{address[:line1]}' AND postcode = '#{address[:postcode]}' ORDER BY date_of_expiry DESC LIMIT 1")

    unless assessments_at_address.entries.empty?
      address[:id] = "RRN-#{assessments_at_address[0]['assessment_id']}"
    end

    scheme_assessor_id = assessor["scheme_assessor_id"]

    date_of_assessment = "20" + rand(16..19).to_s.rjust(2, "0") + rand(1..12).to_s.rjust(2, "0") + rand(1..28).to_s.rjust(2, "0")
    date_registered = (Date.parse(date_of_assessment) + rand(1..5).day).strftime("%Y-%m-%d")
    date_of_expiry = (Date.parse(date_of_assessment) + 10.year).strftime("%Y-%m-%d")
    current_energy_efficiency_rating = rand(1..99)
    internal_current_carbon_emission = current_carbon_emission.sample
    internal_potential_carbon_emission = potential_carbon_emission.sample
    internal_lighting_cost_current = lighting_cost_current.sample
    internal_heating_cost_current = heating_cost_current.sample
    internal_hot_water_cost_current = hot_water_cost_current.sample
    internal_lighting_cost_potential = lighting_cost_potential.sample
    internal_heating_cost_potential = heating_cost_potential.sample
    internal_hot_water_cost_potential = hot_water_cost_potential.sample
    internal_current_space_heating_demand = current_space_heating_demand.sample
    internal_current_water_heating_demand = current_water_heating_demand.sample
    internal_impact_of_loft_insulation = impact_of_loft_insulation.sample
    internal_impact_of_cavity_insulation = impact_of_cavity_insulation.sample
    internal_impact_of_solid_wall_insulation = impact_of_solid_wall_insulation.sample
    assessment_id = "1111-2222-3333-4444-" + number.to_s.rjust(4, "0")
    internal_related_party_disclosure_number = related_party_disclosure_number.sample
    internal_related_party_disclosure_text = related_party_disclosure_text.sample
    internal_property_summary = property_summary.sample

    unless internal_related_party_disclosure_text.nil?
      internal_related_party_disclosure_number = "NULL"
    end

    query =
      "INSERT INTO
        assessments
          (
            assessment_id,
            date_of_assessment,
            date_registered,
            dwelling_type,
            type_of_assessment,
            total_floor_area,
            current_energy_efficiency_rating,
            potential_energy_efficiency_rating,
            postcode,
            date_of_expiry,
            address_line1,
            address_line2,
            address_line3,
            address_line4,
            town,
            address_id,
            current_carbon_emission,
            potential_carbon_emission,
            current_space_heating_demand,
            current_water_heating_demand,
            impact_of_loft_insulation,
            impact_of_cavity_insulation,
            impact_of_solid_wall_insulation,
            scheme_assessor_id,
            related_party_disclosure_number,
            related_party_disclosure_text,
            property_summary,
            lighting_cost_current,
            heating_cost_current,
            hot_water_cost_current,
            lighting_cost_potential,
            heating_cost_potential,
            hot_water_cost_potential
          )
        VALUES(
          '#{assessment_id}',
          '#{date_of_assessment}',
          '#{date_registered}',
          '#{dwelling_type.sample}',
          '#{type_of_assessment}',
          '#{rand(20..200)}',
          '#{current_energy_efficiency_rating}',
          '#{[current_energy_efficiency_rating + rand(1..20), 99].min}',
          '#{address[:postcode]}',
          '#{date_of_expiry}',
          '#{address[:line1]}',
          '#{address[:line2]}',
          '#{address[:line3]}',
          '#{address[:line4]}',
          '#{address[:town]}',
          '#{address[:id]}',
          '#{internal_current_carbon_emission}',
          '#{internal_potential_carbon_emission}',
          '#{internal_current_space_heating_demand}',
          '#{internal_current_water_heating_demand}',
          '#{internal_impact_of_loft_insulation}',
          '#{internal_impact_of_cavity_insulation}',
          '#{internal_impact_of_solid_wall_insulation}',
          '#{scheme_assessor_id}',
          #{internal_related_party_disclosure_number},
          '#{internal_related_party_disclosure_text}',
          '#{internal_property_summary}',
          '#{internal_lighting_cost_current}',
          '#{internal_heating_cost_current}',
          '#{internal_hot_water_cost_current}',
          '#{internal_lighting_cost_potential}',
          '#{internal_heating_cost_potential}',
          '#{internal_hot_water_cost_potential}'
        )"

    green_deal_plan_id = ActiveRecord::Base.connection.execute("SELECT green_deal_plan_id FROM green_deal_assessments WHERE assessment_id = '#{assessment_id}'")
    ActiveRecord::Base.connection.execute("DELETE FROM green_deal_assessments WHERE green_deal_plan_id = '#{green_deal_plan_id.values.flatten.first}'")
    ActiveRecord::Base.connection.execute("DELETE FROM green_deal_plans WHERE green_deal_plan_id = '#{green_deal_plan_id.values.flatten.first}'")
    ActiveRecord::Base.connection.execute("DELETE FROM domestic_epc_energy_improvements WHERE assessment_id = '#{assessment_id}'")
    ActiveRecord::Base.connection.execute("DELETE FROM assessments WHERE assessment_id = '#{assessment_id}'")
    ActiveRecord::Base.connection.execute(query)

    rand(0..10).times do |sequence|
      internal_improvement_code = improvement_code[sequence]
      internal_indicative_cost = indicative_cost.sample
      internal_typical_saving = typical_saving.sample
      internal_improvement_category = improvement_category.sample
      internal_improvement_type = improvement_type.sample
      internal_energy_performance_rating_improvement = energy_performance_rating_improvement.sample
      internal_environmental_impact_rating_improvement = environmental_impact_rating_improvement.sample
      internal_green_deal_category_code = green_deal_category_code.sample

      recommended_improvements_query =
        "INSERT INTO
        domestic_epc_energy_improvements
          (
            assessment_id,
            sequence,
            improvement_code,
            indicative_cost,
            typical_saving,
            improvement_category,
            improvement_type,
            energy_performance_rating_improvement,
            environmental_impact_rating_improvement,
            green_deal_category_code
          )
        VALUES(
            '#{assessment_id}',
            '#{sequence}',
            '#{internal_improvement_code}',
            '#{internal_indicative_cost}',
            '#{internal_typical_saving}',
            '#{internal_improvement_category}',
            '#{internal_improvement_type}',
            '#{internal_energy_performance_rating_improvement}',
            '#{internal_environmental_impact_rating_improvement}',
            '#{internal_green_deal_category_code}'
        )"

      ActiveRecord::Base.connection.execute(recommended_improvements_query)
    end
  end
end
