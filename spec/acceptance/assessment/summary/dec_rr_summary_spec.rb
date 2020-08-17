# frozen_string_literal: true

describe "Acceptance::AssessmentSummary::DEC-RR" do
  include RSpecRegisterApiServiceMixin

  context "when a valid DEC-RR 8.0.0 is lodged" do
    let(:xml_file) do
      File.read File.join Dir.pwd, "spec/fixtures/samples/dec-rr.xml"
    end
    let(:scheme_id) { add_scheme_and_get_id }
    let(:response) do
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0000").body,
        symbolize_names: true,
      )
    end

    before do
      assessor = AssessorStub.new.fetch_request_body(nonDomesticDec: "ACTIVE")

      add_assessor(scheme_id, "SPEC000000", assessor)
      dec_rr = Nokogiri.XML(xml_file)
      lodge_assessment(
        assessment_body: dec_rr.to_xml,
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )

      dec_file = File.read File.join Dir.pwd, "spec/fixtures/samples/dec.xml"
      dec = Nokogiri.XML(dec_file)
      dec.at("RRN").content = "0000-0000-0000-0000-1111"
      lodge_assessment(
        assessment_body: dec.to_xml,
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )
    end

    it "returns the assessment" do
      expect(response[:data]).to eq(
        {
          typeOfAssessment: "DEC-RR",
          assessmentId: "0000-0000-0000-0000-0000",
          reportType: "2",
          dateOfExpiry: "2028-05-03",
          address: {
            addressLine1: "1 Lonely Street",
            addressLine2: nil,
            addressLine3: nil,
            addressLine4: nil,
            town: "Post-Town0",
            postcode: "A0 0AA",
          },
          advisoryReport: {
              technicalInformation: {
                  buildingEnvironment: "Air Conditioning",
                  floorArea: "10",
              }
          },
        },
      )
    end
  end
end
