module Domain
  class Assessor
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
      domestic_energy_performance_qualification
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
      @domestic_energy_performance_qualification =
        domestic_energy_performance_qualification
    end

    def to_hash
      {
        first_name: @first_name,
        last_name: @last_name,
        middle_names: @middle_names,
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
        contact_details: { telephone_number: @telephone_number, email: @email },
        search_results_comparison_postcode: @search_results_comparison_postcode,
        qualifications: {
          domestic_energy_performance_certificates:
            if @domestic_energy_performance_qualification == 'ACTIVE'
              'ACTIVE'
            else
              'INACTIVE'
            end
        }
      }
    end
  end
end
