describe "fetching Retrofit Funding Scheme details from the API", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }
  let(:scheme_id) do
    scheme_id = add_scheme_and_get_id
    add_assessor(
      scheme_id:,
      assessor_id: "SPEC000000",
      body: fetch_assessor_stub.fetch_request_body(
        domestic_rd_sap: "ACTIVE",
        domestic_sap: "ACTIVE",
      ),
    )

    scheme_id
  end

  let(:rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }

  let(:expected_rdsap_details) do
    { assessment: {
      address: {
        addressLine1: "1 Some Street",
        addressLine2: "",
        addressLine3: "",
        addressLine4: "",
        town: "Whitbury",
        postcode: "A0 0AA",
      },
      uprn: "000000000000",
      lodgementDate: "2020-05-04",
      expiryDate: "2030-05-03",
      currentBand: "e",
      propertyType: "Mid-terrace house",
      builtForm: "Semi-Detached",
    } }
  end

  let(:expected_404_message) { "No domestic EPCs found for this UPRN" }
  let(:expected_400_message) { "The UPRN parameter is badly formatted" }

  context "when fetching Retrofit Funding Scheme details with a valid UPRN" do
    before do
      lodge_assessment(
        assessment_body: rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-20.0.0",
      )
    end

    it "returns the details of the matching assessment in the expected format" do
      response = JSON.parse(
        retrofit_funding_details_by_uprn("000000000000", accepted_responses: [200]).body,
        symbolize_names: true,
      )
      expect(response[:data]).to eq expected_rdsap_details
    end

    it "returns an 404 error when no matching assessments exist" do
      response = JSON.parse(
        retrofit_funding_details_by_uprn("000000000001", accepted_responses: [404]).body,
        symbolize_names: true,
      )
      expect(response[:errors][0][:title]).to eq expected_404_message
    end

    it "returns a 403 error when the wrong auth scope is provided" do
      response = JSON.parse(
        retrofit_funding_details_by_uprn("000000000000", accepted_responses: [403], scopes: %w[wrong:scope]).body,
        symbolize_names: true,
      )
      expect(response[:errors][0][:code]).to eq "UNAUTHORISED"
    end

    context "when there is more than one assessment associated with the UPRN" do
      let(:latest_rrn) { "0000-0000-0000-0000-0013" }

      before do
        superseded_rdsap = Nokogiri::XML rdsap_xml.clone
        superseded_rdsap.at("RRN").children = latest_rrn
        superseded_rdsap.at("Registration-Date").children = "2019-05-04"

        lodge_assessment(
          assessment_body: superseded_rdsap.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )
      end

      it "returns the Retrofit Funding Scheme details of the most recent assessment" do
        response = JSON.parse(
          retrofit_funding_details_by_uprn("000000000000").body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_rdsap_details
      end
    end

    context "when the assessment associated with the UPRN has been opted-out" do
      before do
        opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")
      end

      it "returns a 404 error when the only matching assessment is opted out" do
        response = JSON.parse(
          retrofit_funding_details_by_uprn("000000000000", accepted_responses: [404]).body,
          symbolize_names: true,
        )
        expect(response[:errors][0][:title]).to eq expected_404_message
      end
    end

    context "when the assessment associated with the UPRN has been cancelled" do
      before do
        update_assessment_status(
          assessment_id: "0000-0000-0000-0000-0000",
          assessment_status_body: {
            "status": "CANCELLED",
          },
          accepted_responses: [200],
          auth_data: {
            scheme_ids: [scheme_id],
          },
        )
      end

      it "returns a 404 error when the only matching assessment is cancelled" do
        response = JSON.parse(
          retrofit_funding_details_by_uprn("000000000000", accepted_responses: [404]).body,
          symbolize_names: true,
        )
        expect(response[:errors][0][:title]).to eq expected_404_message
      end
    end

    context "when the assessment associated with the UPRN has been marked as not-for-issue" do
      before do
        update_assessment_status(
          assessment_id: "0000-0000-0000-0000-0000",
          assessment_status_body: {
            "status": "NOT_FOR_ISSUE",
          },
          accepted_responses: [200],
          auth_data: {
            scheme_ids: [scheme_id],
          },
        )
      end

      it "returns a 404 error when the only matching assessment is marked not-for issue" do
        response = JSON.parse(
          retrofit_funding_details_by_uprn("000000000000", accepted_responses: [404]).body,
          symbolize_names: true,
        )
        expect(response[:errors][0][:title]).to eq expected_404_message
      end
    end
  end

  context "when a request is made with a non-valid UPRN" do
    before do
      lodge_assessment(
        assessment_body: rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-20.0.0",
      )
    end

    it "returns a 400 error when the UPRN is not 12 digits long" do
      response = JSON.parse(
        retrofit_funding_details_by_uprn("0000000112", accepted_responses: [400]).body,
        symbolize_names: true,
      )
      expect(response[:errors][0][:code]).to eq "BAD_REQUEST"
      expect(response[:errors][0][:title]).to eq expected_400_message
    end

    it "returns a 400 error when the UPRN contains the prefix" do
      response = JSON.parse(
        retrofit_funding_details_by_uprn("UPRN-000000000001", accepted_responses: [400]).body,
        symbolize_names: true,
      )
      expect(response[:errors][0][:title]).to eq expected_400_message
    end
  end
end
