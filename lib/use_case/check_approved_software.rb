module UseCase
  class CheckApprovedSoftware
    def initialize(logger: nil)
      @logger = logger || Logger.new($stdout)
    end

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
      @domestic_software ||= DomesticSoftwareList.new logger: logger
    end

    def non_domestic_software
      @non_domestic_software ||= NonDomesticSoftwareList.new logger: logger
    end

    def domestic_schemas
      %w[RdSAP SAP]
    end

    def domestic_schema?(schema_name)
      domestic_schemas.include?(schema_name.split("-").first)
    end

    attr_reader :logger
  end

  # The domestic software list is provided as a JSON string encoding a hash with
  # the single key "software", which in turn contains a hash that has software
  # names (as strings) as keys, with each entry containing a list of currently
  # approved software major versions.
  # A lodged XML with any version number *beginning with* one of the major
  # version numbers listed is allowed.
  #
  # Example JSON string:
  #
  #   {"software":{"Acme Lodgerator":["1", "2"],"Lodg-o":["v6.7","v6.6"]}}
  #
  class DomesticSoftwareList
    def initialize(logger: nil)
      @software = case ENV["DOMESTIC_APPROVED_SOFTWARE"].nil?
                  when false
                    JSON.parse(ENV["DOMESTIC_APPROVED_SOFTWARE"])["software"]
                  when true
                    {}
                  end
    rescue JSON::ParserError => e
      logger.error("The domestic software list (JSON) has a syntax error, meaning the software validation cannot occur. Parse error: #{e.message}") if logger
      @software = {}
    end

    def match?(name:, version:)
      return false unless software.key?(name)

      software[name].each do |approved_major_version|
        if version.start_with? approved_major_version
          return true
        end
      end
      false
    end

    def list_exists?
      !software.empty?
    end

  private

    attr_reader :software
  end

  # The non-domestic software list is provided as a JSON string encoding a hash
  # with the single key "software", which in turn contains a list of known
  # software identifiers (including versioning, with software names duplicated
  # where necessary).
  # A lodged XML with any version number that *exactly matches* one of the
  # software identifier strings listed is allowed.
  #
  # Example JSON string:
  #
  #   {"software":["Bentley Lodgement Ace, V2.4","Sentinel, v4.6h","Xyzzy, Official, 2.0"]}
  #
  class NonDomesticSoftwareList
    def initialize(logger: nil)
      @software = case ENV["NON_DOMESTIC_APPROVED_SOFTWARE"].nil?
                  when false
                    JSON.parse(ENV["NON_DOMESTIC_APPROVED_SOFTWARE"])["software"]
                  when true
                    []
                  end
    rescue JSON::ParserError => e
      logger.error("The non-domestic software list (JSON) has a syntax error, meaning the software validation cannot occur. Parse error: #{e.message}") if logger
      @software = {}
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
