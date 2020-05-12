context "searching for an address" do
  include RSpecAssessorServiceMixin

  context "with an invalid combination of parameters" do
    describe "with an invalid buildingReferenceNumber" do
      it "returns a validation error" do
        response = assertive_get(
          "/api/address/search?buildingReferenceNumber=DOESNOTEXIST",
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
          "/api/address/search",
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
        assertive_get("/api/address/search", [401], false, nil, nil)
      end
    end

    describe "without the scope address:search" do
      it "returns a 403" do
        assertive_get("/api/address/search", [403], true, nil, nil)
      end
    end
  end
end
