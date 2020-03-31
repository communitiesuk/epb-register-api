module Boundary
  class AssessorRequest
    attr_reader :registered_by_id,
                :scheme_assessor_id,
                :first_name,
                :last_name,
                :middle_names,
                :date_of_birth,
                :email,
                :telephone_number,
                :search_results_comparison_postcode,
                :domestic_rd_sap_qualification,
                :non_domestic_sp3_qualification,
                :non_domestic_cc4_qualification

    def initialize(body, scheme_assessor_id, registered_by_id)
      @scheme_assessor_id = scheme_assessor_id
      @first_name = body[:first_name]
      @last_name = body[:last_name]
      @middle_names = body[:middle_names]
      @date_of_birth = body[:date_of_birth]

      @email = body.dig(:contact_details, :email)
      @telephone_number = body.dig(:contact_details, :telephone_number)
      @registered_by_id = registered_by_id
      @search_results_comparison_postcode =
        body[:search_results_comparison_postcode]
      @domestic_rd_sap_qualification =
        body.dig(:qualifications, :domestic_rd_sap)
      @non_domestic_sp3_qualification =
        body.dig(:qualifications, :non_domestic_sp3)
      @non_domestic_cc4_qualification =
        body.dig(:qualifications, :non_domestic_cc4)
    end
  end
end
