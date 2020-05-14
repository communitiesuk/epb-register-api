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
                :also_known_as,
                :address_line1,
                :address_line2,
                :address_line3,
                :town,
                :postcode,
                :company_reg_no,
                :company_address_line1,
                :company_address_line2,
                :company_address_line3,
                :company_town,
                :company_postcode,
                :company_website,
                :company_telephone_number,
                :company_email,
                :company_name,
                :domestic_sap_qualification,
                :domestic_rd_sap_qualification,
                :non_domestic_sp3_qualification,
                :non_domestic_cc4_qualification,
                :non_domestic_dec_qualification,
                :non_domestic_nos3_qualification,
                :non_domestic_nos4_qualification,
                :non_domestic_nos5_qualification

    def initialize(body: nil, scheme_assessor_id: nil, registered_by_id: nil)
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
      @also_known_as = body[:also_known_as]
      @address_line1 = body[:address_line1]
      @address_line2 = body[:address_line2]
      @address_line3 = body[:address_line3]
      @town = body[:town]
      @postcode = body[:postcode]
      @company_reg_no = body[:company_reg_no]
      @company_address_line1 = body[:company_address_line1]
      @company_address_line2 = body[:company_address_line2]
      @company_address_line3 = body[:company_address_line3]
      @company_town = body[:company_town]
      @company_postcode = body[:company_postcode]
      @company_website = body[:company_website]
      @company_telephone_number = body[:company_telephone_number]
      @company_email = body[:company_email]
      @company_name = body[:company_name]
      @domestic_sap_qualification = body.dig(:qualifications, :domestic_sap)
      @domestic_rd_sap_qualification =
        body.dig(:qualifications, :domestic_rd_sap)
      @non_domestic_sp3_qualification =
        body.dig(:qualifications, :non_domestic_sp3)
      @non_domestic_cc4_qualification =
        body.dig(:qualifications, :non_domestic_cc4)
      @non_domestic_dec_qualification =
        body.dig(:qualifications, :non_domestic_dec)
      @non_domestic_nos3_qualification =
        body.dig(:qualifications, :non_domestic_nos3)
      @non_domestic_nos4_qualification =
        body.dig(:qualifications, :non_domestic_nos4)
      @non_domestic_nos5_qualification =
        body.dig(:qualifications, :non_domestic_nos5)
    end
  end
end
