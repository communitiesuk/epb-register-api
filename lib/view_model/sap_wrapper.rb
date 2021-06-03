module ViewModel
  class SapWrapper
    attr_reader :schema_type, :report_type

    def initialize(xml, schema_type)
      @schema_type = schema_type
      xml_doc = Nokogiri.XML(xml).remove_namespaces!
      @report_type = xml_doc.at("Report-Type")&.content

      case @schema_type
      when "SAP-Schema-18.0.0"
        @view_model = ViewModel::SapSchema1800::CommonSchema.new xml
      when "SAP-Schema-17.1"
        @view_model = ViewModel::SapSchema171::CommonSchema.new xml
      when "SAP-Schema-17.0"
        @view_model = ViewModel::SapSchema170::CommonSchema.new xml
      when "SAP-Schema-16.3"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchema163::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchema163::Sap.new(xml)
          end
      when "SAP-Schema-16.2"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchema162::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchema162::Sap.new(xml)
          end
      when "SAP-Schema-16.1"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchema161::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchema161::Sap.new(xml)
          end
      when "SAP-Schema-16.0"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchema160::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchema160::Sap.new(xml)
          end
      when "SAP-Schema-15.0"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchema150::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchema150::Sap.new(xml)
          end
      when "SAP-Schema-14.2"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchema142::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchema142::Sap.new(xml)
          end
      when "SAP-Schema-14.1"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchema141::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchema141::Sap.new(xml)
          end
      when "SAP-Schema-14.0"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchema140::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchema140::Sap.new(xml)
          end
      when "SAP-Schema-13.0"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchema130::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchema130::Sap.new(xml)
          end
      when "SAP-Schema-12.0"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchema120::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchema120::Sap.new(xml)
          end
      when "SAP-Schema-11.2"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchema112::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchema112::Sap.new(xml)
          end
      when "SAP-Schema-11.0"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchema110::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchema110::Sap.new(xml)
          end
      when "SAP-Schema-10.2"
        @view_model =
          @report_type == "2" ? ViewModel::SapSchema102::Rdsap.new(xml) : nil
      when "SAP-Schema-NI-18.0.0"
        @view_model = ViewModel::SapSchemaNi1800::CommonSchema.new xml
      when "SAP-Schema-NI-17.4"
        @view_model = ViewModel::SapSchemaNi174::CommonSchema.new xml
      when "SAP-Schema-NI-17.3"
        @view_model = ViewModel::SapSchemaNi173::CommonSchema.new xml
      when "SAP-Schema-NI-17.2"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchemaNi172::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchemaNi172::Sap.new(xml)
          end
      when "SAP-Schema-NI-17.1"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchemaNi171::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchemaNi171::Sap.new(xml)
          end
      when "SAP-Schema-NI-17.0"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchemaNi170::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchemaNi170::Sap.new(xml)
          end
      when "SAP-Schema-NI-16.1"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchemaNi161::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchemaNi161::Sap.new(xml)
          end
      when "SAP-Schema-NI-16.0"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchemaNi160::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchemaNi160::Sap.new(xml)
          end
      when "SAP-Schema-NI-15.0"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchemaNi150::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchemaNi150::Sap.new(xml)
          end
      when "SAP-Schema-NI-14.2"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchemaNi142::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchemaNi142::Sap.new(xml)
          end
      when "SAP-Schema-NI-14.1"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchemaNi141::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchemaNi141::Sap.new(xml)
          end
      when "SAP-Schema-NI-14.0"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchemaNi140::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchemaNi140::Sap.new(xml)
          end
      when "SAP-Schema-NI-13.0"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchemaNi130::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchemaNi130::Sap.new(xml)
          end
      when "SAP-Schema-NI-12.0"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchemaNi120::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchemaNi120::Sap.new(xml)
          end
      when "SAP-Schema-NI-11.2"
        @view_model =
          case @report_type
          when "2"
            ViewModel::SapSchemaNi112::Rdsap.new(xml)
          when "3"
            ViewModel::SapSchemaNi112::Sap.new(xml)
          end
      else
        raise ArgumentError, "Unsupported schema type"
      end

      raise ArgumentError, "Unsupported schema type" if @view_model.nil?
    end

    def type
      @view_model.type_of_assessment.to_sym
    end

    def to_hash
      estimated_energy_cost =
        Helper::EstimatedCostPotentialSavingHelper.new.estimated_cost(
          @view_model.heating_cost_current,
          @view_model.hot_water_cost_current,
          @view_model.lighting_cost_current,
        )
      {
        type_of_assessment: @view_model.type_of_assessment,
        assessment_id: @view_model.assessment_id,
        date_of_expiry: @view_model.date_of_expiry,
        date_of_assessment: @view_model.date_of_assessment,
        date_of_registration: @view_model.date_of_registration,
        date_registered: @view_model.date_of_registration,
        address_id: @view_model.address_id,
        address_line1: @view_model.address_line1,
        address_line2: @view_model.address_line2,
        address_line3: @view_model.address_line3,
        address_line4: nil,
        town: @view_model.town,
        postcode: @view_model.postcode,
        address: {
          address_id: @view_model.address_id,
          address_line1: @view_model.address_line1,
          address_line2: @view_model.address_line2,
          address_line3: @view_model.address_line3,
          address_line4: nil,
          town: @view_model.town,
          postcode: @view_model.postcode,
        },
        assessor: {
          scheme_assessor_id: @view_model.scheme_assessor_id,
          name: @view_model.assessor_name,
          contact_details: {
            email: @view_model.assessor_email,
            telephone: @view_model.assessor_telephone,
          },
        },
        current_carbon_emission:
          convert_to_big_decimal(@view_model.current_carbon_emission),
        current_energy_efficiency_band:
          Helper::EnergyBandCalculator.domestic(
            @view_model.current_energy_rating,
          ),
        current_energy_efficiency_rating: @view_model.current_energy_rating,
        dwelling_type: @view_model.dwelling_type,
        estimated_energy_cost: estimated_energy_cost,
        main_fuel_type: @view_model.main_fuel_type,
        heat_demand: {
          current_space_heating_demand:
            @view_model.current_space_heating_demand&.to_i,
          current_water_heating_demand:
            @view_model.current_water_heating_demand&.to_i,
          impact_of_cavity_insulation: @view_model.impact_of_cavity_insulation,
          impact_of_loft_insulation: @view_model.impact_of_loft_insulation,
          impact_of_solid_wall_insulation:
            @view_model.impact_of_solid_wall_insulation,
        },
        heating_cost_current: @view_model.heating_cost_current,
        heating_cost_potential: @view_model.heating_cost_potential,
        hot_water_cost_current: @view_model.hot_water_cost_current,
        hot_water_cost_potential: @view_model.hot_water_cost_potential,
        lighting_cost_current: @view_model.lighting_cost_current,
        lighting_cost_potential: @view_model.lighting_cost_potential,
        potential_carbon_emission:
          convert_to_big_decimal(@view_model.potential_carbon_emission),
        potential_energy_efficiency_band:
          Helper::EnergyBandCalculator.domestic(
            @view_model.potential_energy_rating,
          ),
        potential_energy_efficiency_rating: @view_model.potential_energy_rating,
        potential_energy_saving:
          Helper::EstimatedCostPotentialSavingHelper.new.potential_saving(
            @view_model.heating_cost_potential,
            @view_model.hot_water_cost_potential,
            @view_model.lighting_cost_potential,
            estimated_energy_cost,
          ),
        primary_energy_use: @view_model.primary_energy_use,
        energy_consumption_potential: @view_model.energy_consumption_potential,
        property_age_band: @view_model.property_age_band,
        property_summary: @view_model.property_summary,
        recommended_improvements:
          @view_model.improvements.map do |improvement|
            improvement[:energy_performance_band_improvement] =
              Helper::EnergyBandCalculator.domestic(
                improvement[:energy_performance_rating_improvement],
              )
            improvement
          end,
        lzc_energy_sources: @view_model.lzc_energy_sources,
        related_party_disclosure_number:
          @view_model.related_party_disclosure_number,
        related_party_disclosure_text:
          @view_model.related_party_disclosure_text,
        tenure: @view_model.tenure,
        transaction_type: @view_model.transaction_type,
        total_floor_area: convert_to_big_decimal(@view_model.total_floor_area),
        status: @view_model.status,
        environmental_impact_current: @view_model.environmental_impact_current,
        environmental_impact_potential:
          @view_model.environmental_impact_potential,
        co2_emissions_current_per_floor_area:
          @view_model.co2_emissions_current_per_floor_area,
        mains_gas: @view_model.mains_gas,
        level: @view_model.level,
        top_storey: @view_model.top_storey,
        storey_count: @view_model.storey_count,
        main_heating_controls: @view_model.main_heating_controls,
        multiple_glazed_proportion: @view_model.multiple_glazed_proportion,
        glazed_area: @view_model.glazed_area,
        habitable_room_count: @view_model.habitable_room_count,
        heated_room_count: @view_model.heated_room_count,
        low_energy_lighting: @view_model.low_energy_lighting,
        fixed_lighting_outlets_count: @view_model.fixed_lighting_outlets_count,
        low_energy_fixed_lighting_outlets_count:
          @view_model.low_energy_fixed_lighting_outlets_count,
        open_fireplaces_count: @view_model.open_fireplaces_count,
        hot_water_description: @view_model.hot_water_description,
        hot_water_energy_efficiency_rating:
          @view_model.hot_water_energy_efficiency_rating,
        hot_water_environmental_efficiency_rating:
          @view_model.hot_water_environmental_efficiency_rating,
        window_description: @view_model.window_description,
        window_energy_efficiency_rating:
          @view_model.window_energy_efficiency_rating,
        window_environmental_efficiency_rating:
          @view_model.window_environmental_efficiency_rating,
        secondary_heating_description:
          @view_model.secondary_heating_description,
        secondary_heating_energy_efficiency_rating:
          @view_model.secondary_heating_energy_efficiency_rating,
        secondary_heating_environmental_efficiency_rating:
          @view_model.secondary_heating_environmental_efficiency_rating,
        lighting_description: @view_model.lighting_description,
        lighting_energy_efficiency_rating:
          @view_model.lighting_energy_efficiency_rating,
        lighting_environmental_efficiency_rating:
          @view_model.lighting_environmental_efficiency_rating,
        photovoltaic_roof_area_percent:
          @view_model.photovoltaic_roof_area_percent,
        heat_loss_corridor: @view_model.heat_loss_corridor,
        wind_turbine_count: @view_model.wind_turbine_count,
        unheated_corridor_length: @view_model.unheated_corridor_length,
        built_form:
          Helper::XmlEnumsToOutput.xml_value_to_string(@view_model.built_form),
        mainheat_description:
          @view_model.all_main_heating_descriptions.join(", "),
        extensions_count:
          if @view_model.respond_to?(:extensions_count)
            @view_model.extensions_count
          end,
        addendum: @view_model.addendum,
      }
    end

    def to_report
      {
        assessment_id: @view_model.assessment_id,
        inspection_date: @view_model.date_of_assessment,
        lodgement_date: @view_model.date_of_registration,
        building_reference_number: @view_model.building_reference_number,
        address1: @view_model.address_line1,
        address2: @view_model.address_line2,
        address3: @view_model.address_line3,
        posttown: @view_model.town,
        postcode: @view_model.postcode,
        construction_age_band:
          Helper::XmlEnumsToOutput.construction_age_band_lookup(
            @view_model.main_dwelling_construction_age_band_or_year,
            schema_type,
            report_type,
          ),
        current_energy_rating:
          Helper::EnergyBandCalculator.domestic(
            @view_model.current_energy_rating,
          ),
        potential_energy_rating:
          Helper::EnergyBandCalculator.domestic(
            @view_model.potential_energy_rating,
          ),
        current_energy_efficiency: @view_model.current_energy_rating.to_s.chomp,
        potential_energy_efficiency:
          @view_model.potential_energy_rating.to_s.chomp,
        property_type:
          Helper::XmlEnumsToOutput.property_type(@view_model.property_type),
        tenure: Helper::XmlEnumsToOutput.tenure(@view_model.tenure),
        transaction_type:
          Helper::XmlEnumsToOutput.transaction_type(
            @view_model.transaction_type,
            report_type,
          ),
        environment_impact_current: @view_model.environmental_impact_current,
        environment_impact_potential:
          @view_model.environmental_impact_potential,
        energy_consumption_current: @view_model.primary_energy_use,
        energy_consumption_potential: @view_model.energy_consumption_potential,
        co2_emissions_current: @view_model.current_carbon_emission,
        co2_emiss_curr_per_floor_area:
          @view_model.co2_emissions_current_per_floor_area,
        co2_emissions_potential: @view_model.potential_carbon_emission,
        heating_cost_current: @view_model.heating_cost_current,
        heating_cost_potential: @view_model.heating_cost_potential,
        hot_water_cost_current: @view_model.hot_water_cost_current,
        hot_water_cost_potential: @view_model.hot_water_cost_potential,
        lighting_cost_current: @view_model.lighting_cost_current,
        lighting_cost_potential: @view_model.lighting_cost_potential,
        total_floor_area: @view_model.total_floor_area,
        mains_gas_flag:
          @view_model.respond_to?(:mains_gas) ? @view_model.mains_gas : nil,
        flat_top_storey: @view_model.top_storey,
        flat_storey_count: @view_model.storey_count,
        multi_glaze_proportion: @view_model.multiple_glazed_proportion,
        glazed_area:
          Helper::XmlEnumsToOutput.glazed_area_rdsap(@view_model.glazed_area),
        number_habitable_rooms: @view_model.habitable_room_count,
        number_heated_rooms: @view_model.heated_room_count,
        low_energy_lighting: @view_model.low_energy_lighting,
        fixed_lighting_outlets_count: @view_model.fixed_lighting_outlets_count,
        low_energy_fixed_lighting_outlets_count:
          @view_model.low_energy_fixed_lighting_outlets_count,
        number_open_fireplaces: @view_model.open_fireplaces_count,
        hotwater_description: @view_model.hot_water_description,
        hot_water_energy_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.hot_water_energy_efficiency_rating,
          ),
        hot_water_env_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.hot_water_environmental_efficiency_rating,
          ),
        wind_turbine_count: @view_model.wind_turbine_count,
        heat_loss_corridor:
          Helper::XmlEnumsToOutput.heat_loss_corridor(
            @view_model.heat_loss_corridor,
          ),
        unheated_corridor_length: @view_model.unheated_corridor_length,
        windows_description: @view_model.window_description,
        windows_energy_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.window_energy_efficiency_rating,
          ),
        windows_env_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.window_environmental_efficiency_rating,
          ),
        sheating_energy_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.secondary_heating_energy_efficiency_rating,
          ),
        sheating_env_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.secondary_heating_environmental_efficiency_rating,
          ),
        secondheat_description: @view_model.secondary_heating_description,
        lighting_description: @view_model.lighting_description,
        lighting_energy_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.lighting_energy_efficiency_rating,
          ),
        lighting_env_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.lighting_environmental_efficiency_rating,
          ),
        photo_supply: @view_model.photovoltaic_roof_area_percent,
        built_form:
          Helper::XmlEnumsToOutput.xml_value_to_string(@view_model.built_form),
        mainheat_description:
          @view_model.all_main_heating_descriptions.join(", "),
        report_type: @view_model.report_type,
        mainheatcont_description:
          @view_model.all_main_heating_controls_descriptions.first,
        roof_description: @view_model.all_roof_descriptions.first,
        roof_energy_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.all_roof_energy_efficiency_rating.first,
          ),
        roof_env_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.all_roof_env_energy_efficiency_rating.first,
          ),
        walls_description: @view_model.all_wall_descriptions.first,
        walls_energy_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.all_wall_energy_efficiency_rating.first,
          ),
        walls_env_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.all_wall_env_energy_efficiency_rating.first,
          ),
        energy_tariff:
          Helper::XmlEnumsToOutput.energy_tariff(
            @view_model.energy_tariff,
            report_type,
          ),
        floor_level: @view_model.floor_level,
        mainheat_energy_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.all_main_heating_energy_efficiency.first,
          ),
        mainheat_env_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.all_main_heating_environmental_efficiency.first,
          ),
        extension_count: @view_model.extensions_count,
        solar_water_heating_flag: @view_model.solar_water_heating_flag,
        mechanical_ventilation:
          Helper::XmlEnumsToOutput.mechanical_ventilation(
            @view_model.mechanical_ventilation,
            schema_type,
            report_type,
          ),
        floor_height:
          if @view_model.respond_to?(:floor_height)
            @view_model.floor_height.first
          end,
        main_fuel:
          Helper::XmlEnumsToOutput.main_fuel_sap(@view_model.main_fuel_type),
        floor_description: @view_model.all_floor_descriptions.first,
        floor_energy_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.all_floor_energy_efficiency_rating.first,
          ),
        floor_env_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.all_floor_env_energy_efficiency_rating.first,
          ),
        mainheatc_energy_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.all_main_heating_controls_energy_efficiency.first,
          ),
        mainheatc_env_eff:
          Helper::XmlEnumsToOutput.energy_rating_string(
            @view_model.all_main_heating_controls_environmental_efficiency.first,
          ),
        glazed_type:
          Helper::XmlEnumsToOutput.glazed_type_rdsap(
            @view_model.multi_glazing_type,
          ),
      }
    end

    def to_recommendation_report
      complete_recommendations =
        @view_model.recommendations_for_report.each do |recommendations|
          recommendations[:assessment_id] = @view_model.assessment_id
        end

      { recommendations: complete_recommendations }
    end

    def get_view_model
      @view_model
    end

  private

    def convert_to_big_decimal(node)
      return "" unless node

      BigDecimal(node)
    end
  end
end
