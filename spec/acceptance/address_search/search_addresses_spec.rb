describe "Acceptance::AddressSearch", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  context "with an invalid combination of parameters" do
    describe "no parameters" do
      let(:response) do
        assertive_get_in_search_scope(
          "/api/search/addresses",
          accepted_responses: [422],
        ).body
      end

      it "returns a validation error" do
        expect(response).to include "INVALID_REQUEST"
      end
    end

    context "with an incorrect combination of parameters" do
      describe "building reference number and another parameter" do
        it_behaves_like "assertive_get", path:  "/api/search/addresses?addressId=RRN-0000-0000-0000-0000-0000&something=test", status_code: 422, scopes: %w[address:search], assertion: " validation failure"
      end

      describe "postcode and another parameter" do
        it_behaves_like "assertive_get", path:  "/api/search/addresses?postcode=A0%200AA&something=test", status_code: 422, scopes: %w[address:search], assertion: " validation failure"
      end

      describe "street, town and another parameter" do
        it_behaves_like "assertive_get", path:  "/api/search/addresses?street=place&town=place&something=test", status_code: 422, scopes: %w[address:search], assertion: " validation failure"
      end
    end
  end

  context "with invalid auth details" do
    describe "with no authentication token" do
      it_behaves_like "assertive_get", path: "/api/search/addresses", status_code: 401, scopes: [], should_authenticate: false
    end

    describe "without the scope address:search" do
      it_behaves_like "assertive_get", path:  "/api/search/addresses?street=place&town=place&something=test", status_code: 403, scopes: []
    end
  end

  context "with an incomplete address" do
    describe "an address with only line1, town, and postcode" do
      let(:scheme_id) { add_scheme_and_get_id }

      let(:response) do
        JSON.parse(
          assertive_get_in_search_scope(
            "/api/search/addresses?postcode=A0%200AA",
          ).body,
          symbolize_names: true,
        )
      end

      before do
        add_assessor(scheme_id:, assessor_id: "SPEC000000", body: VALID_ASSESSOR_REQUEST_BODY)

        lodge_assessment(
          assessment_body: Samples.xml("RdSAP-Schema-20.0.0"),
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
        )
      end

      it "has nil for line2" do
        expect(response[:data][:addresses][0][:line2]).to be_nil
      end

      it "has nil for line3" do
        expect(response[:data][:addresses][0][:line3]).to be_nil
      end
    end
  end
end
