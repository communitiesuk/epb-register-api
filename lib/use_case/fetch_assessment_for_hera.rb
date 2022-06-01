module UseCase
  class FetchAssessmentForHera
    def initialize(hera_gateway:, summary_use_case:)
      @hera_gateway = hera_gateway
      @summary_use_case = summary_use_case
    end

    def execute(rrn:)
      hera_from_view_model = get_hera_hash rrn: rrn
      return nil if hera_from_view_model.nil?

      assessment_summary = @summary_use_case.execute(rrn)

      Domain::AssessmentHeraDetails.new type_of_assessment: hera_from_view_model[:type_of_assessment],
                                        address: hera_from_view_model[:address].transform_values { |v| v || "" },
                                        lodgement_date: hera_from_view_model[:date_of_registration],
                                        is_latest_assessment_for_address: !assessment_summary[:superseded_by],
                                        property_type: hera_from_view_model[:dwelling_type],
                                        built_form: hera_from_view_model[:built_form],
                                        property_age_band: hera_from_view_model[:main_dwelling_construction_age_band_or_year],
                                        walls_description: pluck_property_summary_descriptions(hera_hash: hera_from_view_model, feature_type: "wall"),
                                        floor_description: pluck_property_summary_descriptions(hera_hash: hera_from_view_model, feature_type: "floor"),
                                        roof_description: pluck_property_summary_descriptions(hera_hash: hera_from_view_model, feature_type: "roof"),
                                        windows_description: pluck_property_summary_descriptions(hera_hash: hera_from_view_model, feature_type: "window"),
                                        main_heating_description: hera_from_view_model[:main_heating_category],
                                        main_fuel_type: hera_from_view_model[:main_fuel_type],
                                        has_hot_water_cylinder: hera_from_view_model[:has_hot_water_cylinder] == "true"
    end

  private

    def get_hera_hash(rrn:)
      result = @hera_gateway.fetch_by_rrn rrn
      return nil if result.nil?

      ViewModel::Factory.new.create(result["xml"], result["schema_type"], rrn).to_hera_hash
    end

    def pluck_property_summary_descriptions(hera_hash:, feature_type:)
      hera_hash[:property_summary]
        .select { |feature| [feature_type, "#{feature_type}s"].include?(feature[:name]) } # descriptions in property summary can be called "wall" or "walls", or "window" or "windows" depending on whether SAP or RdSAP due to slight schema divergence here
        .map { |feature| feature[:description] }
    end
  end
end
