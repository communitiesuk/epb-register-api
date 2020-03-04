module Domain
  class Assessor
    attr_reader :registered_by_id, :scheme_assessor_id

    def initialize(
      scheme_assessor_id,
      first_name,
      last_name,
      middle_names,
      date_of_birth,
      email,
      telephone_number,
      registered_by_id,
      registered_by_name,
      search_results_comparison_postcode,
      domestic_rd_sap_qualification
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
      @domestic_rd_sap_qualification =
        domestic_rd_sap_qualification
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
            @date_of_birth.strftime('%Y-%m-%d')
          else
            Date.parse(@date_of_birth)
          end,
        contact_details: {},
        search_results_comparison_postcode: @search_results_comparison_postcode,
        qualifications: {
          domestic_rd_sap:
            if @domestic_rd_sap_qualification == 'ACTIVE'
              'ACTIVE'
            else
              'INACTIVE'
            end
        }
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
        domestic_rd_sap_qualification:
          @domestic_rd_sap_qualification
      }
    end
  end
end
