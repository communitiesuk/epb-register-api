describe "Acceptance::ScotlandAssessmentStatus", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  context "when fetching an assessor" do
    let(:use_case) { instance_double(UseCase::FetchScottishAssessorById) }

    let(:data) do
      {
        first_name: "Joe",
        middle_names: "T",
        last_name: "Bloggs",
        email: "j.t.bloggs@example.com",
        address: {
          address_line1: "22 Acacia Avenue",
          address_line2: "",
          address_line3: "",
          town: "Fulchester",
          postcode: "FL23 4JA",
        },
        scheme_assessor_id: "TEST000001",
        registered_by: "Stroma Certification Ltd",
        qualifications: {
          domestic_rd_sap: "ACTIVE",
          domestic_sap: "ACTIVE",
          non_domestic_dec: "ACTIVE",
          non_domestic_nos3: "ACTIVE",
          non_domestic_nos4: "ACTIVE",
          non_domestic_nos5: "ACTIVE",
          non_domestic_sp3: "ACTIVE",
          non_domestic_cc4: "ACTIVE",
          gda: "ACTIVE",
          scotland_rdsap: "ACTIVE",
          scotland_sap_existing_building: "ACTIVE",
          scotland_sap_new_building: "ACTIVE",
          scotland_dec_and_ar: "ACTIVE",
          scotland_nondomestic_existing_building: "ACTIVE",
          scotland_nondomestic_new_building: "ACTIVE",
          scotland_section63: "ACTIVE",
        },
      }
    end

    let(:expected_response) do
      { "data" =>
         { "firstName" => "Joe",
           "middleNames" => "T",
           "lastName" => "Bloggs",
           "email" => "j.t.bloggs@example.com",
           "address" => { "addressLine1" => "22 Acacia Avenue", "addressLine2" => "", "addressLine3" => "", "town" => "Fulchester", "postcode" => "FL23 4JA" },
           "schemeAssessorId" => "TEST000001",
           "registeredBy" => "Stroma Certification Ltd",
           "qualifications" =>
            { "domesticRdSap" => "ACTIVE",
              "domesticSap" => "ACTIVE",
              "nonDomesticDec" => "ACTIVE",
              "nonDomesticNos3" => "ACTIVE",
              "nonDomesticNos4" => "ACTIVE",
              "nonDomesticNos5" => "ACTIVE",
              "nonDomesticSp3" => "ACTIVE",
              "nonDomesticCc4" => "ACTIVE",
              "gda" => "ACTIVE",
              "scotlandRdsap" => "ACTIVE",
              "scotlandSapExistingBuilding" => "ACTIVE",
              "scotlandSapNewBuilding" => "ACTIVE",
              "scotlandDecAndAr" => "ACTIVE",
              "scotlandNondomesticExistingBuilding" => "ACTIVE",
              "scotlandNondomesticNewBuilding" => "ACTIVE",
              "scotlandSection63" => "ACTIVE" } },
        "meta" => {
          "dataSentAt" => "2021-06-21T01:00:00.000+01:00",
        } }
    end

    before do
      allow(ApiFactory).to receive(:fetch_scottish_assessor_by_id).and_return(use_case)
      allow(use_case).to receive(:execute).with(scheme_assessor_id: "TEST000001").and_return(data)
      allow(use_case).to receive(:execute).with(scheme_assessor_id: "invalid-id").and_raise(Boundary::AssessorNotFoundException)
    end

    it "returns an assessor" do
      response = scottish_get_assessor_by_id(scheme_assessor_id: "TEST000001")
      response_json = JSON.parse(response.body)
      expect(response_json).to eq expected_response
    end

    context "when no assessor is found" do
      let(:expected_response) do
        {
          "errors" => [
            {
              "code" => "NOT_FOUND",
              "title" => "The thing you are looking for is not here",
            },
          ],
        }
      end

      it "returns a 400 error" do
        response = scottish_get_assessor_by_id(scheme_assessor_id: "invalid-id", accepted_responses: [400])
        response_json = JSON.parse(response.body)
        expect(response_json).to eq expected_response
      end
    end

    it_behaves_like "when checking an endpoint requires bearer token access", end_point: "scotland/v1/assessors/some_id", scopes: %w[scotland_data:fetch]
  end
end
