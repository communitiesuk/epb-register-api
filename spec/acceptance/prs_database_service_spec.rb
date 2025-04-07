describe "fetching data for the PRS database from API", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  let(:scheme_id) { add_scheme_and_get_id }

  let(:rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }
  let(:cepc_xml) { Samples.xml "CEPC-8.0.0", "cepc" }
  let(:expected_rdsap_details) do

  end
  let(:expected_sap_details) do
  end

  before do
    add_super_assessor(scheme_id: scheme_id)

    lodge_assessment(
      assessment_body: cepc_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      schema_name: "CEPC-8.0.0",
      )

    updated_rdsap = Nokogiri::XML rdsap_xml.clone
    updated_rdsap.at("RRN").children = "0000-0000-0000-0000-0001"
    updated_rdsap.at("Registration-Date").children = "2020-05-04"

    lodge_assessment(
      assessment_body: updated_rdsap.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      schema_name: "RdSAP-Schema-20.0.0",
      )

    updated_rdsap = Nokogiri::XML rdsap_xml.clone
    updated_rdsap.at("RRN").children = "0000-0000-0000-0000-0002"
    updated_rdsap.at("Registration-Date").children = "2024-05-04"

    lodge_assessment(
      assessment_body: updated_rdsap.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      migrated: true,
      )
  end

  context "when getting certificate details using the RRN" do
    context "when the RRN correctly formated" do
      it "returns the matching certificate details" do
        expected_response =   {:address=>
                                 {:addressLine1=>"1 Some Street",
                                  :addressLine2=>"",
                                  :addressLine3=>"",
                                  :addressLine4=>"",
                                  :town=>"Whitbury",
                                  :postcode=>"SW1A 2AA"},
                               :currentEnergyEfficiencyRating=>50,
                               :epcRrn=>"0000-0000-0000-0000-0002",
                               :expiryDate=>"2034-05-03T00:00:00.000Z",
                               :latestEpcRrnForAddress=>"0000-0000-0000-0000-0002",
                               :currentEnergyEfficiencyBand=>"e"}
        response = JSON.parse(
          prs_database_details_by_rrn("0000-0000-0000-0000-0002").body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_response
      end

      it "returns the rrn for the latest epc for an address when given an old rrn " do
        response = JSON.parse(
          prs_database_details_by_rrn("0000-0000-0000-0000-0001").body,
          symbolize_names: true,
          )

        expect(response[:data][:latestEpcRrnForAddress]).to eq "0000-0000-0000-0000-0002"
      end

      it "returns an error when no certificate exists" do
        response = JSON.parse(
          prs_database_details_by_rrn(
            "0000-0000-0000-0000-0009",
            accepted_responses: [404],
            ).body,
          symbolize_names: true,
          )

        expect(response[:errors][0][:title]).to eq "No assessment details could be found for that query"
      end

      it "returns an error when gen the rrn for a cepc" do
        response = JSON.parse(
          prs_database_details_by_rrn(
            "0000-0000-0000-0000-0000",
            accepted_responses: [400],
            ).body,
          symbolize_names: true,
          )

        expect(response[:errors][0][:title]).to eq "The requested assessment type is not SAP or RdSAP"
      end
    end

    context "when the RRN is incorrectly formatted" do
      it "returns an error" do
        response = JSON.parse(
          prs_database_details_by_rrn(
            "0000-00-0000-0000-0001",
            accepted_responses: [400],
            ).body,
          symbolize_names: true,
          )

        expect(response[:errors][0][:title]).to eq "The value provided for the rrn parameter in the search query was not valid"
      end
    end

    context "when the certificate is deleted" do
      it "returns an error" do
        update_assessment_status(
          assessment_id: "0000-0000-0000-0000-0001",
          assessment_status_body: {
            "status": "CANCELLED",
          },
          accepted_responses: [200],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          )

        response = JSON.parse(
          prs_database_details_by_rrn(
            "0000-0000-0000-0000-0001",
            accepted_responses: [404],
            ).body,
          symbolize_names: true,
          )

        expect(response[:errors][0][:title]).to eq "No assessment details could be found for that query"
      end
    end
  end

  context "when getting certificate details using the correctly formatted UPRN" do
    it "returns the matching certificate details" do
      expected_response =   {:address=>
                               {:addressLine1=>"1 Some Street",
                                :addressLine2=>"",
                                :addressLine3=>"",
                                :addressLine4=>"",
                                :town=>"Whitbury",
                                :postcode=>"SW1A 2AA"},
                             :currentEnergyEfficiencyRating=>50,
                             :epcRrn=>"0000-0000-0000-0000-0002",
                             :expiryDate=>"2034-05-03T00:00:00.000Z",
                             :latestEpcRrnForAddress=>"0000-0000-0000-0000-0002",
                             :currentEnergyEfficiencyBand=>"e"}
      response = JSON.parse(
        prs_database_details_by_uprn("UPRN-000000000000").body,
        symbolize_names: true,
        )

      expect(response[:data]).to eq expected_response
    end
  end

  context "when the UPRN is incorrectly formatted" do
    it "returns an error" do
      response = JSON.parse(
        prs_database_details_by_uprn(
          "NOT-A-UPRN-000000000000",
          accepted_responses: [400],
          ).body,
        symbolize_names: true,
        )

      expect(response[:errors][0][:title]).to eq "The value provided for the uprn parameter in the search query was not valid"
    end
  end
end
