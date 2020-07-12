describe "Acceptance::Schemes" do
  include RSpecRegisterApiServiceMixin

  context "getting a list of schemes security" do
    it "returns status 401 with no authentication" do
      schemes_list([401], false)
    end
    it "returns status 403 without the right scope" do
      schemes_list([403], true, {}, %w[wrong:scope])
    end
  end

  context "getting an empty list of schemes" do
    it "returns status 200" do
      schemes_list([200], true, {})
    end

    it "returns JSON" do
      expect(schemes_list.headers["Content-Type"]).to eq("application/json")
    end

    it "includes an empty list of schemes" do
      parsed_response = JSON.parse(schemes_list.body, symbolize_names: true)
      expect(parsed_response).to eq({ data: { schemes: [] }, meta: {} })
    end
  end

  context "adding a scheme security" do
    it "returns status 401 with no authentication" do
      add_scheme("TEST", [401], false)
    end

    it "returns status 403 with wrong scopes" do
      add_scheme("TEST", [403], true, {}, %w[wrong:scope])
    end
  end

  context "posting to the schemes api" do
    it "returns status 201" do
      add_scheme("XYMZALERO", [201])
    end

    it "returns json" do
      response = add_scheme("XYMZALERO", [201])
      expect(response.headers["Content-Type"]).to eq("application/json")
    end

    it "is visible in the list of schemes" do
      add_scheme("XYMZALERO")
      response = schemes_list
      get_response = JSON.parse(response.body)
      expect(get_response["data"]["schemes"][0]["name"]).to eq("XYMZALERO")
    end

    it "is set to active by default" do
      add_scheme("XYMZALERO")
      response = schemes_list
      get_response = JSON.parse(response.body)
      expect(get_response["data"]["schemes"][0]["active"]).to be_truthy
    end

    it "cannot have the same name twice" do
      add_scheme("XYMZALERO", [201])
      add_scheme("XYMZALERO", [400])
    end
  end

  context "updating a scheme" do
    context "security" do
      it "returns status 401 with no authentication" do
        update_scheme(123, {}, [401], false)
      end
      it "returns status 403 without the right scope" do
        update_scheme(123, {}, [403], true, {}, %w[wrong:scope])
      end
    end
    it "returns 404 for a scheme that doesnt exist" do
      update_scheme(123, { name: "name", active: true }, [404])
    end

    it "returns 204 for a scheme that does exist" do
      scheme_id = add_scheme_and_get_id("My old scheme name")
      update_scheme(scheme_id, { name: "My new scheme name", active: false })
    end

    it "rejects a message without the required keys" do
      scheme_id = add_scheme_and_get_id("My old scheme name")
      update_scheme(scheme_id, {}, [401])
    end
  end
end
