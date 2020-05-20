desc "Truncate all certificate data"

task :truncate_certificate do
  unless ENV["STAGE"] == "staging" || ENV["STAGE"] == "integration"
    exit
  end

  ActiveRecord::Base.connection.execute("TRUNCATE TABLE assessments RESTART IDENTITY CASCADE")
end

desc "Import some random certificate data"

task :generate_certificate do
  if ENV["STAGE"] == "production"
    exit
  end

  ActiveRecord::Base.logger = nil

  dwelling_type = ["end-terrace house", "terrace house", "flat", "bungalow", "mansion", "castle"]
  type_of_assessment = %w[RdSAP SAP]
  postcode = ["E2 0SZ", "NW3 2UU", "SW1A 2AA", "SE1 1TE", "SW1X 7XL", "W1B 5BT", "BH2 5BH", "CF10 2EQ", "TR19 7AA", "M4 6WX"]
  address_line1 = ["Flat 32", "Milton Mews", "Flat 22", "First floor flat", "2D", "Flat 99", "33 Caliban Tower", "1 Hamlet Building", "9 Peter Pan Building", "", "", "", ""]
  address_line2 = ["7a Parkhill Road", "Spooky Avenue", "9 Priti Patel Street", "11 Makup Street", "11 Mornington Crescent", "Spooky Street", "Thomas Lane"]
  address_line3 = Array.new(20, "")
  address_line3.push("The Dormers")
  address_line4 = Array.new(100, "")
  address_line4.push("Westminster")
  town = %w[Brighton Bournemouth London Cardiff Newcastle Manchester Bristol]
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

  result = ActiveRecord::Base.connection.execute("SELECT * FROM assessors ORDER BY random() LIMIT 2000")

  result.each_with_index do |assessor, number|
    line_1 = address_line1.sample
    line_2 = address_line2.sample
    scheme_assessor_id = assessor["scheme_assessor_id"]
    if line_1.empty?
      line_1 = line_2
      line_2 = ""
    end

    line_3 = address_line3.sample
    line_4 = address_line4.sample
    internal_postcode = postcode.sample
    date_of_assessment = "20" + rand(6..19).to_s.rjust(2, "0") + rand(1..12).to_s.rjust(2, "0") + rand(1..28).to_s.rjust(2, "0")
    date_registered = (Date.parse(date_of_assessment) + rand(1..5).day).strftime("%Y-%m-%d")
    date_of_expiry =  (Date.parse(date_of_assessment) + 10.year).strftime("%Y-%m-%d")
    internal_town = town.sample
    current_energy_efficiency_rating = rand(1..99)
    internal_current_carbon_emission = current_carbon_emission.sample
    internal_potential_carbon_emission = potential_carbon_emission.sample
    internal_current_space_heating_demand = current_space_heating_demand.sample
    internal_current_water_heating_demand = current_water_heating_demand.sample
    internal_impact_of_loft_insulation = impact_of_loft_insulation.sample
    internal_impact_of_cavity_insulation = impact_of_cavity_insulation.sample
    internal_impact_of_solid_wall_insulation = impact_of_solid_wall_insulation.sample
    assessment_id = "4321-8765-0987-7654-" + number.to_s.rjust(4, "0")
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
            address_summary,
            current_energy_efficiency_rating,
            potential_energy_efficiency_rating,
            postcode,
            date_of_expiry,
            address_line1,
            address_line2,
            address_line3,
            address_line4,
            town,
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
            property_summary
          )
        VALUES(
          '#{assessment_id}',
          '#{date_of_assessment}',
          '#{date_registered}',
          '#{dwelling_type.sample}',
          '#{type_of_assessment.sample}',
          '#{rand(20..200)}',
          '#{ActiveRecord::Base.sanitize_sql((line_1 + ', ' + line_2 + ', ' + internal_town + ', ' + internal_postcode).gsub(', , ', ', '))}',
          '#{current_energy_efficiency_rating}',
          '#{[current_energy_efficiency_rating + rand(1..20), 99].min}',
          '#{internal_postcode}',
          '#{date_of_expiry}',
          '#{ActiveRecord::Base.sanitize_sql(line_1)}',
          '#{ActiveRecord::Base.sanitize_sql(line_2)}',
          '#{line_3}',
          '#{line_4}',
          '#{internal_town}',
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
          '#{internal_property_summary}'
        )"

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
