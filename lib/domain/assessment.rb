module Domain
  class Assessment
    TYPE2LODGEMENT = {
      "CEPC": Domain::CepcAssessment,
      "SAP": Domain::SapAssessment,
      "RdSAP": Domain::RdsapAssessment,
      "DEC-RR": Domain::DecRrAssessment,
      "DEC": Domain::DecAssessment,
      "CEPC-RR": Domain::CepcRrAssessment,
      "AC-CERT": Domain::AcCertAssessment,
      "AC-REPORT": Domain::AcReportAssessment,
    }.freeze

    def initialize(data)
      if %i[CEPC-RR].include? data[:type_of_assessment].to_sym
        domain_object = TYPE2LODGEMENT[data[:type_of_assessment].to_sym]

        needed_params = domain_object.instance_method(:initialize).parameters.map(&:second)

        @assessment = domain_object.new(**data.slice(*needed_params))
      else
        @assessment = TYPE2LODGEMENT[data[:type_of_assessment].to_sym].new(data)
      end
    end

    def to_hash
      @assessment.to_hash
    end

    def to_record
      @assessment.to_record
    end

    def set(key, value)
      @assessment.set(key, value)
    end

    def get(key)
      @assessment.get(key)
    end

    def is_type?(expected_class)
      @assessment.is_a?(expected_class)
    end
  end
end
