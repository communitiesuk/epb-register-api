module UseCase
  class MatchAssessmentAddress
    def initialize(
      addressing_api_gateway:,
      assessments_address_id_gateway:,
      event_broadcaster:
    )
      @addressing_api_gateway = addressing_api_gateway
      @assessments_address_id_gateway = assessments_address_id_gateway
      @event_broadcaster = event_broadcaster
    end

    def execute(address_line_1:, address_line_2:, address_line_3:, address_line_4:, town:, postcode:, assessment_id:, is_scottish:)
      matches = @addressing_api_gateway.match_address(
        address_line_1:,
        address_line_2:,
        address_line_3:,
        address_line_4:,
        town:,
        postcode:,
      )
      if matches.empty?
        @assessments_address_id_gateway.update_matched_address_id(assessment_id, "none", nil, is_scottish)
        @event_broadcaster.broadcast(:matched_address, assessment_id: assessment_id, matched_uprn: "none")
      elsif matches.length == 1
        @assessments_address_id_gateway.update_matched_address_id(assessment_id, matches.first["uprn"], matches.first["confidence"], is_scottish)
        @event_broadcaster.broadcast(:matched_address, assessment_id: assessment_id, matched_uprn: matches.first["uprn"])
      else
        best_confidence = matches.max_by { |m| m["confidence"].to_f }["confidence"]
        best_matches = matches.select { |m| m["confidence"] == best_confidence }
        if best_matches.length == 1
          @assessments_address_id_gateway.update_matched_address_id(assessment_id, best_matches.first["uprn"], best_matches.first["confidence"], is_scottish)
          @event_broadcaster.broadcast(:matched_address, assessment_id: assessment_id, matched_uprn: best_matches.first["uprn"])
        else
          @assessments_address_id_gateway.update_matched_address_id(assessment_id, "unknown", best_confidence, is_scottish)
          @event_broadcaster.broadcast(:matched_address, assessment_id: assessment_id, matched_uprn: "unknown")
        end
      end
    end
  end
end
