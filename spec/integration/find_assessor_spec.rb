describe "Integration::FilterAndOrderAssessorsByPostcode" do
  include RSpecRegisterApiServiceMixin

  let(:valid_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "SW1A 2AA",
      qualifications: {
        domestic_rd_sap: "ACTIVE",
      },
    }
  end

  def populate_postcode_geolocation
    add_postcodes("SW1A 2AA", 51.503541, -0.12767, "London")
  end

  context "when searching for a postcode" do
    context "when the postcode_geolocation table is empty" do
      it "returns an empty hash" do
        response = Gateway::PostcodesGateway.new.fetch("BF1 3AD")
        expect(response).to eq([])
      end
    end

    context "when the postcode_geolocation table is not empty" do
      it "returns a single record" do
        populate_postcode_geolocation

        response = Gateway::PostcodesGateway.new.fetch("SW1A 2AA")

        expect(response).to eq(
          [
            {
              'postcode': "SW1A 2AA",
              'latitude': 51.503541,
              'longitude': -0.12767,
            },
          ],
        )
      end
    end
  end

  context "when ordering and filtering assessors by postcode" do
    it "the returned assessor is within 0.0 distance" do
      scheme_id = authenticate_and { add_scheme_and_get_id }

      authenticate_and do
        add_assessor(scheme_id:, assessor_id: "SCHE423322", body: valid_assessor_request_body)
      end

      populate_postcode_geolocation

      postcode = Gateway::PostcodesGateway.new.fetch("SW1A 2AA").first

      assessors =
        Gateway::AssessorsGateway.new.search(
          postcode[:latitude],
          postcode[:longitude],
          %w[domesticRdSap],
        )

      expect(assessors.first[:distance_from_postcode_in_miles]).to eq(0.0)
    end
  end
end
