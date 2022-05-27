describe "fetching domestic epc search results from the API", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:feature_flag) do
    "register-api-domestic-epc-search-endpoint-enabled"
  end

  describe "when calling the address search end point" do
    before do
      allow(Helper::Toggles).to receive(:enabled?)
      allow(Helper::Toggles).to receive(:enabled?).with(feature_flag).and_return(true)
    end

    let(:scope) do
      %w[domestic_epc:assessment:search]
    end

    context "when performing a search with no query parameters" do
      it "receives an appropriate error with a 400" do
        response = JSON.parse(
          find_domestic_epcs_by_arbitrary_params(
            params: {},
            accepted_responses: [400],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "The search query was invalid - please check the provided parameters"
      end
    end

    context "when passing the incorrect scopes" do
      it "returns a 403 UNAUTHORISED response" do
        response = JSON.parse(find_domestic_epcs_by_address(
          postcode: "A0 0AA",
          building_name_or_number: "1",
          accepted_responses: [403],
          scopes: %w[wrong:scope],
        ).body,
                              symbolize_names: true)

        expect(response[:errors][0][:code]).to eq "UNAUTHORISED"
      end
    end

    context "when the feature flag for the this endpoint is not enabled" do
      before do
        allow(Helper::Toggles).to receive(:enabled?).with(feature_flag).and_return(false)
      end

      it "receives a 501 with an appropriate error" do
        response = JSON.parse(
          find_domestic_epcs_by_arbitrary_params(
            params: {},
            accepted_responses: [501],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "This endpoint is not implemented"
      end
    end
  end
end
