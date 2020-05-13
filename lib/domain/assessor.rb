# frozen_string_literal: true

module Domain
  class Assessor
    attr_reader :registered_by_id,
                :scheme_assessor_id,
                :domestic_rd_sap_qualification,
                :domestic_sap_qualification,
                :non_domestic_nos3_qualification

    def initialize(
      scheme_assessor_id: nil,
      first_name: nil,
      last_name: nil,
      middle_names: nil,
      date_of_birth: nil,
      email: nil,
      telephone_number: nil,
      registered_by_id: nil,
      registered_by_name: nil,
      search_results_comparison_postcode: nil,
      domestic_sap_qualification: nil,
      domestic_rd_sap_qualification: nil,
      non_domestic_sp3_qualification: nil,
      non_domestic_cc4_qualification: nil,
      non_domestic_dec_qualification: nil,
      non_domestic_nos3_qualification: nil,
      non_domestic_nos4_qualification: nil,
      non_domestic_nos5_qualification: nil
    )
      @scheme_assessor_id = scheme_assessor_id
      @first_name = first_name
      @last_name = last_name
      @middle_names = middle_names
      @date_of_birth = date_of_birth
      @email = email
      @telephone_number = telephone_number
      @registered_by_id = registered_by_id
      @registered_by_name = registered_by_name
      @search_results_comparison_postcode = search_results_comparison_postcode
      @domestic_sap_qualification = domestic_sap_qualification
      @domestic_rd_sap_qualification = domestic_rd_sap_qualification
      @non_domestic_sp3_qualification = non_domestic_sp3_qualification
      @non_domestic_cc4_qualification = non_domestic_cc4_qualification
      @non_domestic_dec_qualification = non_domestic_dec_qualification
      @non_domestic_nos3_qualification = non_domestic_nos3_qualification
      @non_domestic_nos4_qualification = non_domestic_nos4_qualification
      @non_domestic_nos5_qualification = non_domestic_nos5_qualification
    end

    def to_hash
      hash = {
        first_name: @first_name,
        last_name: @last_name,
        registered_by: {
          name: @registered_by_name, scheme_id: @registered_by_id
        },
        scheme_assessor_id: @scheme_assessor_id,
        date_of_birth:
          if @date_of_birth.methods.include?(:strftime)
            @date_of_birth.strftime("%Y-%m-%d")
          else
            Date.parse(@date_of_birth)
          end,
        contact_details: {},
        search_results_comparison_postcode: @search_results_comparison_postcode,
        qualifications: {
          domestic_sap:
            @domestic_sap_qualification == "ACTIVE" ? "ACTIVE" : "INACTIVE",
          domestic_rd_sap:
            @domestic_rd_sap_qualification == "ACTIVE" ? "ACTIVE" : "INACTIVE",
          non_domestic_sp3:
            @non_domestic_sp3_qualification == "ACTIVE" ? "ACTIVE" : "INACTIVE",
          non_domestic_cc4:
            @non_domestic_cc4_qualification == "ACTIVE" ? "ACTIVE" : "INACTIVE",
          non_domestic_dec:
            @non_domestic_dec_qualification == "ACTIVE" ? "ACTIVE" : "INACTIVE",
          non_domestic_nos3:
            if @non_domestic_nos3_qualification == "ACTIVE"
              "ACTIVE"
            else
              "INACTIVE"
            end,
          non_domestic_nos4:
            if @non_domestic_nos4_qualification == "ACTIVE"
              "ACTIVE"
            else
              "INACTIVE"
            end,
          non_domestic_nos5:
            @non_domestic_nos5_qualification == "ACTIVE" ? "ACTIVE" : "INACTIVE",
        },
      }

      hash[:contact_details][:email] = @email if @email
      if @telephone_number
        hash[:contact_details][:telephone_number] = @telephone_number
      end
      hash[:middle_names] = @middle_names if @middle_names
      hash
    end

    def to_record
      {
        scheme_assessor_id: @scheme_assessor_id,
        first_name: @first_name,
        last_name: @last_name,
        middle_names: @middle_names,
        date_of_birth: @date_of_birth,
        email: @email,
        telephone_number: @telephone_number,
        registered_by: @registered_by_id,
        search_results_comparison_postcode: @search_results_comparison_postcode,
        domestic_sap_qualification: @domestic_sap_qualification,
        domestic_rd_sap_qualification: @domestic_rd_sap_qualification,
        non_domestic_sp3_qualification: @non_domestic_sp3_qualification,
        non_domestic_cc4_qualification: @non_domestic_cc4_qualification,
        non_domestic_dec_qualification: @non_domestic_dec_qualification,
        non_domestic_nos3_qualification: @non_domestic_nos3_qualification,
        non_domestic_nos4_qualification: @non_domestic_nos4_qualification,
        non_domestic_nos5_qualification: @non_domestic_nos5_qualification,
      }
    end
  end
end
