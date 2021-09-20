module UseCase
  class CheckApprovedSoftware
    def execute(assessment_xml:, schema_name:)
      if domestic_schema? schema_name
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

    def domestic_schema?(schema_name)
      domestic_schemas.include?(schema_name.split("-").first)
    end
  end

  # The domestic software list, if it exists, is assumed to be provided as a JSON string encoding a hash with the single key "software",
  # which in turn contains a hash that has software names (as strings) as keys, with each entry containing a list of software versions
  # (not necessarily ordered).
  #
  # example JSON string:
  #
  #   {"software":{"Acme Scheme Lodgerator":["1.23", "1.24"],"Lodg-o":["6.5","6.6","6.7"]}}
  #
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

  # The non-domestic software list, if it exists, is assumed to be provided as a JSON string encoding a hash with the single key "software",
  # which in turn contains a list of known software identifiers (including versioning, with software names duplicated where necessary).
  #
  # example JSON string:
  #
  #   {"software":["Bentley Lodgement Ace, V2.4","Sentinel, v4.6h","Xyzzy, Official, 2.0"]}
  #
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
