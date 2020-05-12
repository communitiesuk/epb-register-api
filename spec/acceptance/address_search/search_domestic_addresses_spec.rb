context "searching for an address" do
  include RSpecAssessorServiceMixin

  context "with an invalid combination of parameters" do
    describe "no parameters" do
      it "returns a validation error" do
        assertive_get(
          "/api/address/search",
          [422],
          true,
          nil,
          %w[address:search],
        )
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
