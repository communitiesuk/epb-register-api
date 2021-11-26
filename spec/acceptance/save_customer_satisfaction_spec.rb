describe "Acceptance:SaveCustomerSatisfaction" do
  include RSpecRegisterApiServiceMixin

  def put_customer_satisfaction(body:,
                                scopes:, accepted_responses: [200, 201])
    assertive_put("api/customer-satisfaction",
                  body: body,
                  scopes: scopes,
                  accepted_responses: accepted_responses)
  end

  describe "put /api/customer-satisfaction/ " do
    context "when data send in the put is well formed" do
      let(:data) do
        { "stats_date" => Date.parse("2021-09-01"),
          "satisfied" => 2,
          "very_satisfied" => 1,
          "neither" => 3,
          "dissatisfied" => 4,
          "very_dissatisfied" => 5 }
      end

      it "returns a 200 correct status" do
        put_customer_satisfaction(body: data, scopes: %w[admin:opt_out])
      end

      it "the send data is saved to the database" do
        put_customer_satisfaction(body: data, scopes: %w[admin:opt_out])
        saved_data = ActiveRecord::Base.connection.exec_query("SELECT * FROM customer_satisfaction WHERE month ='2021-09-01'").first
        expect(saved_data["very_satisfied"]).to eq(1)
        expect(saved_data["satisfied"]).to eq(2)
      end
    end

    context "when send data has an invalid date" do
      it "returns a 401  status" do
        data = { "stats_date" => "hello",
                 "satisfied" => 2,
                 "very_satisfied" => 1,
                 "neither" => 3,
                 "dissatisfied" => 4,
                 "very_dissatisfied" => 5 }
        response = put_customer_satisfaction(body: data, scopes: %w[admin:opt_out], accepted_responses: [400])
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)["errors"]).to eq([{ "code" => "INVALID_REQUEST", "title" => "not a valid date" }])
      end
    end

    context "when send data has an valid date a missing key" do
      it "returns a 401  status" do
        data = { "stats_date" => Date.parse("2021-09-01"),
                 "something" => 1,
                 "very_satisfied" => 1,
                 "neither" => 3,
                 "dissatisfied" => 4,
                 "very_dissatisfied" => 5 }
        response = put_customer_satisfaction(body: data, scopes: %w[admin:opt_out], accepted_responses: [400])
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)["errors"]).to eq([{ "code" => "INVALID_REQUEST", "title" => "A required argument is missing: satisfied" }])
      end
    end

    context "when request does not have the correct scopes" do
      it "returns a 403 status for forbidden" do
        put_customer_satisfaction(body: "data", scopes: %w[assessment:search], accepted_responses: [403])
      end
    end
  end
end
