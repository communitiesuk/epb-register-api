require "nokogiri"

module UseCase
  class ExportOpenDataDomestic
    def initialize; end

    def execute(args = {})
      type_of_assessment = args[:type_of_assessment]
      schema_type = args[:schema_type]
      from_date = args[:from_date]
      to_date = args[:to_date]
      number_of_assessments = args[:number_of_assessments]
      batch = args[:batch]
      max_runs = args[:max_runs]

      # puts "Starting extraction at #{Time.now}"

      where =
        "a.opt_out = false AND a.cancelled_at IS NULL AND a.not_for_issue_at IS NULL"

      if type_of_assessment
        where <<
          " AND a.type_of_assessment = " +
          ActiveRecord::Base.connection.quote(type_of_assessment)
      end

      if schema_type
        where <<
          " AND b.schema_type = " +
          ActiveRecord::Base.connection.quote(schema_type)
      end

      if from_date && to_date
        where <<
          " AND a.date_registered BETWEEN " +
          ActiveRecord::Base.connection.quote(from_date) + " AND " +
          ActiveRecord::Base.connection.quote(to_date)
      end

      # number_of_assessments = ActiveRecord::Base.connection.execute("SELECT COUNT(assessment_id) AS number_of_assessments FROM assessments a WHERE #{where}").first["number_of_assessments"]

      # puts "Done getting number of assessments. #{number_of_assessments} in total at #{Time.now}"

      start = 0
      results = []
      while start <= number_of_assessments.to_i
        assessments =
          ActiveRecord::Base.connection.execute(
            "
      SELECT
        a.assessment_id, b.xml, b.schema_type, c.address_id
      FROM
        assessments a
      LEFT JOIN
        assessments_xml b
      ON(a.assessment_id = b.assessment_id)
      LEFT JOIN
        assessments_address_id c
      ON(a.assessment_id = c.assessment_id)
      WHERE
        #{where}
      ORDER BY
        a.date_registered
      LIMIT
        " + batch +
              '
      OFFSET
        ' + start.to_s +
              '
        ',
          )

        # puts "Done getting batch #{start} from DB at #{Time.now}"

        data = []

        assessments.each do |assessment|
          report_model =
            ViewModel::Factory.new.create(
              assessment["xml"],
              assessment["schema_type"],
              assessment["assessment_id"],
            )

          hash = report_model.to_hash

          data.push(
            {
              REPORT_TYPE: hash[:type_of_assessment],
              RRN: hash[:assessment_id],
              INSPECTION_DATE: hash[:date_of_assessment],
              LODGEMENT_DATE: hash[:date_of_registration],
              BUILDING_REFERENCE_NUMBER: assessment["address_id"],
              ADDRESS1: hash[:address][:address_line1],
              ADDRESS2: hash[:address][:address_line2],
              ADDRESS3: hash[:address][:address_line3],
              ADDRESS4: hash[:address][:address_line4],
              POSTTOWN: hash[:address][:town],
              POSTCODE: hash[:address][:postcode],
              CURRENT_ENERGY_EFFICIENCY:
                hash[:current_energy_efficiency_rating],
              CURRENT_ENERGY_RATING: hash[:current_energy_efficiency_band],
              POTENTIAL_ENERGY_EFFICIENCY:
                hash[:potential_energy_efficiency_rating],
              POTENTIAL_ENERGY_RATING: hash[:potential_energy_efficiency_band],
              CONSTRUCTION_AGE_BAND: hash[:property_age_band],
              PROPERTY_TYPE: hash[:dwelling_type],
              TENURE: hash[:tenure],
              ENERGY_CONSUMPTION_CURRENT: hash[:primary_energy_use],
              ENERGY_CONSUMPTION_POTENTIAL: hash[:energy_consumption_potential],
              CO2_EMISSIONS_CURRENT: hash[:current_carbon_emission],
              CO2_EMISSIONS_POTENTIAL: hash[:potential_carbon_emission],
              LIGHTING_COST_CURRENT: hash[:lighting_cost_current],
              LIGHTING_COST_POTENTIAL: hash[:lighting_cost_potential],
              HEATING_COST_CURRENT: hash[:heating_cost_current],
              HEATING_COST_POTENTIAL: hash[:heating_cost_potential],
              HOT_WATER_COST_CURRENT: hash[:hot_water_cost_current],
              HOT_WATER_COST_POTENTIAL: hash[:hot_water_cost_potential],
              TOTAL_FLOOR_AREA: hash[:total_floor_area],
              MAIN_FUEL: hash[:main_fuel_type],
              TRANSACTION_TYPE: hash[:transaction_type],
              ENVIRONMENT_IMPACT_CURRENT: hash[:environmental_impact_current],
              ENVIRONMENT_IMPACT_POTENTIAL:
                hash[:environmental_impact_potential],
              CO2_EMISS_CURR_PER_FLOOR_AREA:
                hash[:co2_emissions_current_per_floor_area],
              MAINS_GAS_FLAG: hash[:mains_gas],
              LEVEL: hash[:level],
              FLAT_TOP_STOREY: hash[:top_storey],
              FLAT_STOREY_COUNT: hash[:storey_count],
              MAIN_HEATING_CONTROLS: hash[:mains_heating_controls],
              MULTI_GLAZE_PROPORTION: hash[:multiple_glazed_proportion],
              GLAZED_AREA: hash[:glazed_area],
              NUMBER_HABITABLE_ROOMS: hash[:habitable_room_count],
              NUMBER_HEATED_ROOMS: hash[:habitable_room_count],
              LOW_ENERGY_LIGHTING: hash[:low_energy_lighting],
              FIXED_LIGHTING_OUTLETS_COUNT: hash[:fixed_lighting_outlets_count],
              LOW_ENERGY_FIXED_LIGHTING_OUTLETS_COUNT: hash[:low_energy_fixed_lighting_outlets_count],
              NUMBER_OPEN_FIREPLACES: hash[:open_fireplaces_count],
              HOTWATER_DESCRIPTION: hash[:hot_water_description],
              HOT_WATER_ENERGY_EFF: hash[:hot_water_energy_efficiency_rating],
              HOT_WATER_ENV_EFF: hash[:hot_water_environmental_efficiency_rating],
              WINDOWS_DESCRIPTION: hash[:window_description],
              WINDOWS_ENERGY_EFF: hash[:window_energy_efficiency_rating],
              WINDOWS_ENV_EFF: hash[:window_environmental_efficiency_rating],
              SECONDHEAT_DESCRIPTION: hash[:secondary_heating_description],
              SHEATING_ENERGY_EFF: hash[:secondary_heating_energy_efficiency_rating],
              SHEATING_ENV_EFF: hash[:secondary_heating_environmental_efficiency_rating],
              LIGHTING_DESCRIPTION: hash[:lighting_description],
              LIGHTING_ENERGY_EFF: hash[:lighting_energy_efficiency_rating],
              LIGHTING_ENV_EFF: hash[:lighting_environmental_efficiency_rating],
              PHOTO_SUPPLY: hash[:photovoltaic_roof_area_percent],
              BUILT_FORM: hash[:built_form],
            },
          )
        end

        # puts "Done preparing array for CSV at #{Time.now}"

        results << CSV.generate(
          write_headers: (start == 0),
          headers: data.first ? data.first.keys : [],
        ) { |csv| data.each { |row| csv << row } }

        start += batch.to_i

        if max_runs && max_runs.to_i <= start
          # puts "Exiting as max runs was reached"
          break
        end
      end
      results
    end
  end
end
