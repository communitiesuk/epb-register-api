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
        matched_uprn = "none"
        confidence = nil
      elsif matches.length == 1
        matched_uprn = matches.first["uprn"]
        confidence = matches.first["confidence"]
      else
        best_confidence = matches.max_by { |m| m["confidence"].to_f }["confidence"]
        best_matches = matches.select { |m| m["confidence"] == best_confidence }
        if best_matches.length == 1
          matched_uprn = best_matches.first["uprn"]
          confidence = best_matches.first["confidence"]
        else
          matched_uprn = "unknown"
          confidence = best_confidence
        end
      end
      @assessments_address_id_gateway.update_matched_address_id(assessment_id, matched_uprn, confidence, is_scottish)
      @event_broadcaster.broadcast(:matched_address, assessment_id: assessment_id, matched_uprn: matched_uprn)
    end
  end
end
