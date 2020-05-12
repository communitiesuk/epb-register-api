context "searching for an address" do
  include RSpecAssessorServiceMixin

  context "with a valid combination of parameters that have no matches" do
    describe "with an valid, not in use buildingReferenceNumber" do
      it "returns an empty result set" do
        response = JSON.parse(assertive_get(
          "/api/search/addresses?buildingReferenceNumber=RRN-1111-2222-3333-4444-5555",
          [200],
          true,
          nil,
          %w[address:search],
        ).body)

        expect(response["data"]["addresses"].length).to eq 0
      end
    end
  end

  context "with an invalid combination of parameters" do
    describe "with an invalid buildingReferenceNumber" do
      it "returns a validation error" do
        response = assertive_get(
          "/api/search/addresses?buildingReferenceNumber=DOESNOTEXIST",
          [422],
          true,
          nil,
          %w[address:search],
        ).body

        expect(response).to include "INVALID_REQUEST"
      end
    end

    describe "no parameters" do
      it "returns a validation error" do
        response = assertive_get(
          "/api/search/addresses",
          [422],
          true,
          nil,
          %w[address:search],
        ).body

        expect(response).to include "INVALID_REQUEST"
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
end
