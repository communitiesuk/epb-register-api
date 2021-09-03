describe "Acceptance::Schemes" do
  include RSpecRegisterApiServiceMixin

  context "when getting a list of schemes" do
    describe "security" do
      it "returns status 401 with no authentication" do
        schemes_list(accepted_responses: [401], should_authenticate: false)
      end

      it "returns status 403 without the right scope" do
        schemes_list(accepted_responses: [403], scopes: %w[wrong:scope])
      end
    end

    context "with no schemes" do
      it "returns status 200" do
        schemes_list(accepted_responses: [200])
      end

      it "returns JSON" do
        expect(schemes_list.headers["Content-Type"]).to eq("application/json")
      end

      it "includes an empty list of schemes" do
        parsed_response = JSON.parse(schemes_list.body, symbolize_names: true)
        expect(parsed_response).to eq({ data: { schemes: [] }, meta: {} })
      end
    end

    context "when adding a scheme" do
      describe "security" do
        it "returns status 401 with no authentication" do
          add_scheme(name: "TEST", accepted_responses: [401], should_authenticate: false)
        end

        it "returns status 403 with wrong scopes" do
          add_scheme(name: "TEST", accepted_responses: [403], scopes: %w[wrong:scope])
        end
      end

      it "returns status 400 if supplied data doesn't match schema" do
        # Integer value for scheme name is invalid - should be a string
        add_scheme(name: 123_456, accepted_responses: [400])
      end

      it "returns status 201" do
        add_scheme(name: "XYMZALERO", accepted_responses: [201])
      end

      it "returns json" do
        response = add_scheme(name: "XYMZALERO", accepted_responses: [201])
        expect(response.headers["Content-Type"]).to eq("application/json")
      end

      it "is visible in the list of schemes" do
        add_scheme(name: "XYMZALERO")
        response = schemes_list
        get_response = JSON.parse(response.body)
        expect(get_response["data"]["schemes"][0]["name"]).to eq("XYMZALERO")
      end

      it "is set to active by default" do
        add_scheme(name: "XYMZALERO")
        response = schemes_list
        get_response = JSON.parse(response.body)
        expect(get_response["data"]["schemes"][0]["active"]).to be_truthy
      end

      it "cannot have the same name twice" do
        add_scheme(name: "XYMZALERO", accepted_responses: [201])
        add_scheme(name: "XYMZALERO", accepted_responses: [400])
      end
    end
  end

  context "when updating a scheme" do
    describe "security" do
      it "returns status 401 with no authentication" do
        update_scheme(scheme_id: 123, accepted_responses: [401], should_authenticate: false)
      end

      it "returns status 403 without the right scope" do
        update_scheme(scheme_id: 123, accepted_responses: [403], scopes: %w[wrong:scope])
      end
    end

    it "returns 404 for a scheme that doesnt exist" do
      update_scheme(scheme_id: 123, body: { name: "name", active: true }, accepted_responses: [404])
    end

    it "rejects a message without the required keys" do
      scheme_id = add_scheme_and_get_id(name: "My old scheme name")
      update_scheme(scheme_id: scheme_id, accepted_responses: [400])
    end

    it "changes all of the details of an existing scheme" do
      scheme_id = add_scheme_and_get_id(name: "My old scheme name")
      update_scheme(scheme_id: scheme_id, body: { name: "My new scheme name", active: false })
      schemes = JSON.parse(schemes_list.body)
      expect(schemes["data"]["schemes"][0]).to eq(
        {
          "name" => "My new scheme name",
          "active" => false,
          "schemeId" => scheme_id,
        },
      )
    end
  end
end
