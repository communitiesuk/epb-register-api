describe "Searching for an assessor by name" do
  include RSpecRegisterApiServiceMixin
  let(:valid_assessor_request) do
    {
      firstName: "Some",
      middleNames: "Middle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      contactDetails: {
        telephoneNumber: "010199991010101",
        email: "person@person.com",
      },
      searchResultsComparisonPostcode: "",
      qualifications: {
        domesticSap: "ACTIVE",
        domesticRdSap: "ACTIVE",
        nonDomesticSp3: "ACTIVE",
        nonDomesticCc4: "ACTIVE",
        nonDomesticDec: "ACTIVE",
        nonDomesticNos3: "ACTIVE",
        nonDomesticNos4: "ACTIVE",
        nonDomesticNos5: "ACTIVE",
        gda: "ACTIVE",
      },
    }
  end

  let(:valid_domestic_assessor_request) do
    {
      firstName: "Some",
      middleNames: "Middle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      contactDetails: {
        telephoneNumber: "010199991010101",
        email: "person@person.com",
      },
      searchResultsComparisonPostcode: "",
      qualifications: {
        domesticSap: "ACTIVE",
        domesticRdSap: "ACTIVE",
        nonDomesticSp3: "INACTIVE",
        nonDomesticCc4: "INACTIVE",
        nonDomesticDec: "INACTIVE",
        nonDomesticNos3: "INACTIVE",
        nonDomesticNos4: "INACTIVE",
        nonDomesticNos5: "INACTIVE",
        gda: "INACTIVE",
      },
    }
  end

  let(:valid_non_domestic_assessor_request) do
    {
      firstName: "Some",
      middleNames: "Middle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      contactDetails: {
        telephoneNumber: "010199991010101",
        email: "person@person.com",
      },
      searchResultsComparisonPostcode: "",
      qualifications: {
        domesticSap: "INACTIVE",
        domesticRdSap: "INACTIVE",
        nonDomesticSp3: "ACTIVE",
        nonDomesticCc4: "ACTIVE",
        nonDomesticDec: "ACTIVE",
        nonDomesticNos3: "ACTIVE",
        nonDomesticNos4: "ACTIVE",
        nonDomesticNos5: "ACTIVE",
        gda: "ACTIVE",
      },
    }
  end

  context "when there are no results" do
    it "returns an empty list" do
      add_scheme_then_assessor(valid_assessor_request)
      response = JSON.parse(assessors_search_by_name("Marten%20Sheikh").body)
      expect(response["data"]["assessors"]).to eq([])
    end
  end

  context "when there are results" do
    it "returns the assessors details" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SCHE554433", valid_assessor_request)
      search_response = assessors_search_by_name("Some%20Person").body
      response = JSON.parse(search_response)

      expect(response["data"]["assessors"][0]).to eq(
        JSON.parse(
          {
            registeredBy: {
              schemeId: scheme_id,
              name: "test scheme",
            },
            schemeAssessorId: "SCHE554433",
            firstName: valid_assessor_request[:firstName],
            lastName: valid_assessor_request[:lastName],
            middleNames: valid_assessor_request[:middleNames],
            searchResultsComparisonPostcode:
              valid_assessor_request[:searchResultsComparisonPostcode],
            qualifications: valid_assessor_request[:qualifications],
            contactDetails: valid_assessor_request[:contactDetails],
          }.to_json,
        ),
      )
    end

    it "lets you search for swapped names" do
      add_scheme_then_assessor(valid_assessor_request)
      search_response = assessors_search_by_name("Person%20Some")
      response = JSON.parse(search_response.body)

      expect(response["data"]["assessors"].size).to eq(1)
    end

    it "raises an error if only one name is given" do
      add_scheme_then_assessor(valid_assessor_request)
      search_response = assessors_search_by_name("Person", "", [400])
      response = JSON.parse(search_response.body)

      expect(response["errors"][0]["title"]).to eq(
        "Both a first name and last name must be provided",
      )
    end

    it "lets you search for half names" do
      add_scheme_then_assessor(valid_assessor_request)
      search_response = assessors_search_by_name("Per%20Some")
      response = JSON.parse(search_response.body)

      expect(response["data"]["assessors"].size).to eq(1)
    end

    it "doesn't return assessors from inactive schemes" do
      scheme_id = add_scheme_and_get_id("My scheme")
      add_assessor(scheme_id, "SCHE554433", valid_assessor_request)
      update_scheme(scheme_id, { name: "My new scheme", active: false })
      search_response = assessors_search_by_name("Per%20Some")
      response = JSON.parse(search_response.body)
      expect(response["data"]["assessors"].size).to eq(0)
    end

    it "only returns assessors with domestic qualifications when specifed" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SCHE554433", valid_domestic_assessor_request)
      add_assessor(scheme_id, "SCHE665544", valid_non_domestic_assessor_request)
      domestic_qualifications = { "domesticRdSap" => "ACTIVE", "domesticSap" => "ACTIVE", "gda" => "INACTIVE", "nonDomesticCc4" => "INACTIVE", "nonDomesticDec" => "INACTIVE", "nonDomesticNos3" => "INACTIVE", "nonDomesticNos4" => "INACTIVE", "nonDomesticNos5" => "INACTIVE", "nonDomesticSp3" => "INACTIVE" }
      search_response = assessors_search_by_name("Per%20Some", "domestic")
      response = JSON.parse(search_response.body)

      expect(response["data"]["assessors"].size).to eq(1)
      expect(response["data"]["assessors"].first["qualifications"]).to eq(domestic_qualifications)
    end

    it "only returns assessors with non domestic (commercial) qualifications when specifed" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SCHE554433", valid_domestic_assessor_request)
      add_assessor(scheme_id, "SCHE665544", valid_non_domestic_assessor_request)
      non_domestic_qualifications = { "domesticRdSap" => "INACTIVE", "domesticSap" => "INACTIVE", "gda" => "ACTIVE", "nonDomesticCc4" => "ACTIVE", "nonDomesticDec" => "ACTIVE", "nonDomesticNos3" => "ACTIVE", "nonDomesticNos4" => "ACTIVE", "nonDomesticNos5" => "ACTIVE", "nonDomesticSp3" => "ACTIVE" }
      search_response = assessors_search_by_name("Per%20Some", "nonDomestic")
      response = JSON.parse(search_response.body)

      expect(response["data"]["assessors"].size).to eq(1)
      expect(response["data"]["assessors"].first["qualifications"]).to eq(non_domestic_qualifications)
    end
  end
end
