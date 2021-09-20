module UseCase
  class CheckApprovedSoftware
    def execute(assessment_xml:, schema_name:)
      case schema_name
      when *domestic_schemas
        !domestic_software.list_exists? || domestic_software.match?(
          name: assessment_xml.at("Calculation-Software-Name")&.children.to_s,
          version: assessment_xml.at("Calculation-Software-Version")&.children.to_s,
        )
      else
        !non_domestic_software.list_exists? || non_domestic_software.match?(identifier: assessment_xml.at("Calculation-Tool")&.children.to_s)
      end
    end

  private

    def domestic_software
      @domestic_software ||= DomesticSoftwareList.new
    end

    def non_domestic_software
      @non_domestic_software ||= NonDomesticSoftwareList.new
    end

    def domestic_schemas
      %w[RdSAP SAP]
    end
  end

  class DomesticSoftwareList
    def initialize
      @software = case ENV["DOMESTIC_APPROVED_SOFTWARE"].nil?
                  when false
                    JSON.parse(ENV["DOMESTIC_APPROVED_SOFTWARE"])["software"]
                  when true
                    {}
                  end
    end

    def match?(name:, version:)
      software.key?(name) && software[name].include?(version)
    end

    def list_exists?
      !software.empty?
    end

  private

    attr_reader :software
  end

  class NonDomesticSoftwareList
    def initialize
      @software = case ENV["NON_DOMESTIC_APPROVED_SOFTWARE"].nil?
                  when false
                    JSON.parse(ENV["NON_DOMESTIC_APPROVED_SOFTWARE"])["software"]
                  when true
                    []
                  end
    end

    def match?(identifier:)
      software.include? identifier
    end

    def list_exists?
      !software.empty?
    end

  private

    attr_reader :software
  end
end
