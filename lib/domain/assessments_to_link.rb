module Domain
  class AssessmentsToLink
    def initialize(data:)
      @data = data
      sort_by_date
    end

    def sort_by_date
      @data.sort_by! { |assessment| assessment["date_registered"] }
    end

    def set_best_address_id(address_base_gateway:)
      find_manually_set_id = @data.find { |assessment| assessment["source"] == "epb_team_update" }
      if !find_manually_set_id.nil?
        @best_address_id = find_manually_set_id["address_id"]
      else
        find_uprn = @data.find { |assessment| assessment["address_id"].start_with?("UPRN") }
        if find_uprn.nil?
          @best_address_id = "RRN-#{@data.first['assessment_id']}"
        else
          @best_address_id = find_uprn["address_id"]
          stripped_uprn = @best_address_id[5..]
          unless address_base_gateway.check_uprn_exists(stripped_uprn)
            @best_address_id = "RRN-#{@data.first['assessment_id']}"
          end
        end
      end
    end

    def get_assessment_ids
      @data.map { |assessment| assessment["assessment_id"] }
    end

    attr_reader :best_address_id, :data
  end
end
