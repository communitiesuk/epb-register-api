describe "Acceptance::ScotlandAssessmentStatus", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  context "when fetching an assessor that exists by ID" do
    let(:use_case) { instance_double(UseCase::FetchScottishAssessorById) }

    let(:expected_response) do
      JSON.parse({ data: {
                     firstName: "Someone",
                     middleNames: "Muddle",
                     lastName: "Person",
                     email: "person@person.com",
                     address: {
                       addressLine1: nil,
                       addressLine2: nil,
                       addressLine3: nil,
                       town: nil,
                       postcode: nil,
                     },
                     schemeAssessorId: "ACME123456",
                     registeredBy: "Scottish Scheme",
                     qualifications: {
                       scotlandRdsap: "ACTIVE",
                       scotlandSapExistingBuilding: "INACTIVE",
                       scotlandSapNewBuilding: "INACTIVE",
                       scotlandDecAndAr: "INACTIVE",
                       scotlandNondomesticExistingBuilding: "INACTIVE",
                       scotlandNondomesticNewBuilding: "INACTIVE",
                       scotlandSection63: "INACTIVE",
                     },
                   },
                   meta: {
                     dataSentAt: Time.now,
                   } }.to_json)
    end

    before do
      Timecop.freeze(2026, 2, 22, 14, 32, 0)
      scheme_id = 999
      Gateway::SchemesGateway::Scheme.create(scheme_id:, name: "Scottish Scheme")

      add_assessor(
        scheme_id:,
        assessor_id: "ACME123456",
        body: AssessorStub.new.fetch_request_body(scotland_rdsap: "ACTIVE"),
      )
    end

    after(:all) do
      Timecop.return
    end

    it "returns the assessor details and Scottish qualifications" do
      response = scottish_get_assessor_by_id(scheme_assessor_id: "ACME123456")
      response_json = JSON.parse(response.body)
      expect(response_json).to eq expected_response
    end

    context "when no assessor with the requested ID is found" do
      let(:expected_response) do
        {
          "errors" => [
            {
              "code" => "NOT_FOUND",
              "title" => "The requested assessor was not found",
            },
          ],
        }
      end

      it "returns a 404 error" do
        response = scottish_get_assessor_by_id(scheme_assessor_id: "invalid-id", accepted_responses: [404])
        response_json = JSON.parse(response.body)
        expect(response_json).to eq expected_response
      end
    end

    it_behaves_like "when checking an endpoint requires bearer token access", end_point: "scotland/v1/assessors/some_id", scopes: %w[scotland_data:fetch]
  end
end
