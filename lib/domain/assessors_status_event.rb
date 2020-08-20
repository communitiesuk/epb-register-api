module Domain
  class AssessorsStatusEvent
    def initialize(
      assessor:,
      scheme_assessor_id:,
      qualification_type:,
      previous_status:,
      new_status:,
      auth_client_id: nil
    )
      @assessor = assessor
      @scheme_assessor_id = scheme_assessor_id
      @qualification_type = qualification_type
      @previous_status = previous_status
      @new_status = new_status
      @auth_client_id = auth_client_id
    end

    def to_record
      {
        assessor: {
          first_name: @assessor[:first_name],
          middle_names: @assessor[:middle_names],
          last_name: @assessor[:last_name],
          date_of_birth: @assessor[:date_of_birth],
        },
        scheme_assessor_id: @scheme_assessor_id,
        qualification_type: @qualification_type,
        previous_status: @previous_status,
        new_status: @new_status,
        recorded_at: Time.now,
        auth_client_id: @auth_client_id,
      }
    end

    def to_hash
      {
        first_name: @assessor["first_name"],
        last_name: @assessor["last_name"],
        middle_names: @assessor["middle_name"],
        scheme_assessor_id: @scheme_assessor_id,
        date_of_birth: @assessor["date_of_birth"],
        qualification_change: {
          qualification_type: @qualification_type,
          previous_status: @previous_status,
          new_status: @new_status,
        },
      }
    end
  end
end
