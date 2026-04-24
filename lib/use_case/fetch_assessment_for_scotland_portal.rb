module UseCase
  class FetchAssessmentForScotlandPortal
    class NotFoundException < StandardError
    end

    def initialize(assessments_xml_gateway:)
      @assessments_xml_gateway = assessments_xml_gateway
    end

    def execute(assessment_id, is_scottish: false)
      assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)

      data = @assessments_xml_gateway.fetch(assessment_id, is_scottish: is_scottish)

      if data.nil?
        raise NotFoundException
      else
        data[:xml]
      end
    end
  end
end
