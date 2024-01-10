shared_context "when lodging XML" do
  include RSpecRegisterApiServiceMixin

  def add_assessor_helper
    scheme_id = add_scheme_and_get_id
    add_assessor(
      scheme_id:,
      assessor_id: "SPEC000000",
      body: AssessorStub.new.fetch_request_body(
        non_domestic_nos3: "ACTIVE",
        non_domestic_nos4: "ACTIVE",
        non_domestic_nos5: "ACTIVE",
        non_domestic_dec: "ACTIVE",
        domestic_rd_sap: "ACTIVE",
        domestic_sap: "ACTIVE",
        non_domestic_sp3: "ACTIVE",
        non_domestic_cc4: "ACTIVE",
        gda: "ACTIVE",
      ),
    )
    scheme_id
  end

  def lodge_epc_helper(scheme_id:, schema:, rrn: nil, assessment_date: nil, uprn: nil, property_type: nil, override: false, postcode: nil)
    xml = Nokogiri.XML Samples.xml(schema)

    unless rrn.nil?
      assessment_id = xml.at("RRN")
      assessment_id.children = rrn
    end

    unless assessment_date.nil?
      registration_date = xml.at("Registration-Date")
      registration_date.children = assessment_date
    end

    unless uprn.nil?
      building_ref_number = xml.at("UPRN")
      building_ref_number.children = uprn
    end

    unless property_type.nil?
      property_type_node = xml.at("Property-Type")
      property_type_node.children = property_type
    end

    unless postcode.nil?
      postcode_node = xml.at("Property Address Postcode")
      postcode_node.children = postcode
    end

    lodge_assessment(
      assessment_body: xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      migrated: true,
      override:,
      schema_name: schema,
    )
  end
end
