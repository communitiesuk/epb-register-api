describe "Acceptance::AddressSearch", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  context "with an invalid combination of parameters" do
    describe "no parameters" do
      let(:response) do
        assertive_get(
          "/api/search/addresses",
          [422],
          true,
          nil,
          %w[address:search],
        ).body
      end

      it "returns a validation error" do
        expect(response).to include "INVALID_REQUEST"
      end
    end

    context "with an incorrect combination of parameters" do
      describe "building reference number and another parameter" do
        it "returns a validation failure" do
          assertive_get(
            "/api/search/addresses?addressId=RRN-0000-0000-0000-0000-0000&something=test",
            [422],
            true,
            nil,
            %w[address:search],
          )
        end
      end

      describe "postcode and another parameter" do
        it "returns a validation failure" do
          assertive_get(
            "/api/search/addresses?postcode=A0%200AA&something=test",
            [422],
            true,
            nil,
            %w[address:search],
          )
        end
      end

      describe "street, town and another parameter" do
        it "returns a validation failure" do
          assertive_get(
            "/api/search/addresses?street=place&town=place&something=test",
            [422],
            true,
            nil,
            %w[address:search],
          )
        end
      end
    end
  end

  context "with invalid auth details" do
    describe "with no authentication token" do
      it "returns a 401" do
        assertive_get("/api/search/addresses", [401], false, nil, nil)
      end
    end

    describe "without the scope address:search" do
      it "returns a 403" do
        assertive_get("/api/search/addresses", [403], true, nil, nil)
      end
    end
  end

  context "with an incomplete address" do
    describe "an address with only line1, town, and postcode" do
      let(:scheme_id) { add_scheme_and_get_id }

      let(:response) do
        JSON.parse(
          assertive_get(
            "/api/search/addresses?postcode=A0%200AA",
            [200],
            true,
            nil,
            %w[address:search],
          ).body,
          symbolize_names: true,
        )
      end

      before do
        add_assessor(scheme_id, "SPEC000000", VALID_ASSESSOR_REQUEST_BODY)

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
