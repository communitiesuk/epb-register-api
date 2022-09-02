module UseCase
  class FetchAssessmentForHera
    def initialize(domestic_digest_gateway:, summary_use_case:)
      @domestic_digest_gateway = domestic_digest_gateway
      @summary_use_case = summary_use_case
    end

    def execute(rrn:)
      domestic_digest = get_domestic_digest rrn: rrn
      return nil if domestic_digest.nil?

      assessment_summary = @summary_use_case.execute(rrn)

      Domain::AssessmentHeraDetails.new type_of_assessment: domestic_digest[:type_of_assessment],
                                        address: domestic_digest[:address].transform_values { |v| v || "" },
                                        lodgement_date: domestic_digest[:date_of_registration],
                                        is_latest_assessment_for_address: !assessment_summary[:superseded_by],
                                        property_type: domestic_digest[:dwelling_type],
                                        built_form: domestic_digest[:built_form],
                                        property_age_band: strip_england_and_wales_prefix(domestic_digest[:main_dwelling_construction_age_band_or_year]),
                                        walls_description: pluck_property_summary_descriptions(hera_hash: domestic_digest, feature_type: "wall"),
                                        floor_description: pluck_property_summary_descriptions(hera_hash: domestic_digest, feature_type: "floor"),
                                        roof_description: pluck_property_summary_descriptions(hera_hash: domestic_digest, feature_type: "roof"),
                                        windows_description: pluck_property_summary_descriptions(hera_hash: domestic_digest, feature_type: "window"),
                                        main_heating_description: domestic_digest[:main_heating_category],
                                        main_fuel_type: domestic_digest[:main_fuel_type],
                                        has_hot_water_cylinder: domestic_digest[:has_hot_water_cylinder] == "true"
    end

  private

    def get_domestic_digest(rrn:)
      result = @domestic_digest_gateway.fetch_by_rrn rrn
      return nil if result.nil?

      ViewModel::Factory.new.create(result["xml"], result["schema_type"], rrn).to_domestic_digest
    end

    def pluck_property_summary_descriptions(hera_hash:, feature_type:)
      hera_hash[:property_summary]
        .select { |feature| [feature_type, "#{feature_type}s"].include?(feature[:name]) } # descriptions in property summary can be called "wall" or "walls", or "window" or "windows" depending on whether SAP or RdSAP due to slight schema divergence here
        .map { |feature| feature[:description] }
    end

    def strip_england_and_wales_prefix(age_band)
      return nil if age_band.nil?

      england_and_wales_prefix = "England and Wales: "
      return age_band unless age_band.start_with? england_and_wales_prefix

      age_band[england_and_wales_prefix.length..]
    end
  end
end
