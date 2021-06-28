describe "Acceptance::SearchForAssessor" do
  include RSpecRegisterApiServiceMixin

  let(:valid_assessor_with_contact_request_body) do
    {
      firstName: "Some",
      middleNames: "Middle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      contactDetails: {
        telephoneNumber: "010199991010101",
        email: "person@person.com",
      },
      searchResultsComparisonPostcode: "SE1 7EZ",
      qualifications: {
        domesticRdSap: "ACTIVE",
        domesticSap: "INACTIVE",
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

  context "when a search postcode is not found" do
    it "returns status 404 for a get" do
      assessors_search("73334", "domesticRdSap", [404])
    end
  end

  context "when searching without the right params" do
    it "returns status 400 for postcode search without qualification" do
      add_postcodes("SE1 7EZ")
      assertive_get(
        "/api/assessors?postcode=SE17EZ",
        [400],
        true,
        {},
        %w[assessor:search],
      )
    end
    it "returns status 400 for no parameters" do
      add_postcodes("SE1 7EZ")
      assertive_get("/api/assessors", [400], true, {}, %w[assessor:search])
    end

    it "rejects a request which searches for a bad qualification" do
      add_postcodes("SA70 7BD")
      assessors_search("SA707BD", "doubleGlazingFitter", [400])
    end
  end

  context "when a search postcode is valid" do
    it "allows searching using a normal looking postcode" do
      add_postcodes("SE1 7EZ")
      scheme_id = add_scheme_and_get_id
      add_assessor scheme_id,
                   "ASSR999999",
                   valid_assessor_with_contact_request_body

      response = assessors_search("SE1 7EZ", "domesticRdSap", [200])
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].length).to eq 1
    end

    it "will search using an outcode if we dont know the postcode" do
      add_outcodes("SE1")
      scheme_id = add_scheme_and_get_id
      add_assessor scheme_id,
                   "ASSR999999",
                   valid_assessor_with_contact_request_body

      response = assessors_search("SE1 7EZ", "domesticRdSap", [200])
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].length).to eq 1
    end

    it "allows searching using a postcode with excessive spaces" do
      add_postcodes("SE1 7EZ")
      scheme_id = add_scheme_and_get_id
      add_assessor scheme_id,
                   "ASSR999999",
                   valid_assessor_with_contact_request_body

      response = assessors_search("  SE1 7EZ   ", "domesticRdSap", [200])
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].length).to eq 1
    end

    it "allows searching using a postcode with no spaces" do
      add_postcodes("SE1 7EZ")
      scheme_id = add_scheme_and_get_id
      add_assessor scheme_id,
                   "ASSR999999",
                   valid_assessor_with_contact_request_body

      response = assessors_search("SE17EZ", "domesticRdSap")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].length).to eq 1
    end

    it "allows searching using a lowercase postcode" do
      add_postcodes("SE1 7EZ")
      scheme_id = add_scheme_and_get_id
      add_assessor scheme_id,
                   "ASSR999999",
                   valid_assessor_with_contact_request_body

      response = assessors_search("se1 7ez", "domesticRdSap")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].length).to eq 1
    end

    it "has the properties we expect" do
      add_postcodes("SE1 7EZ")

      response = assessors_search("SE17EZ", "domesticRdSap")
      response_json = JSON.parse(response.body)

      expect(response_json).to include("data", "meta")
    end

    it "has the assessors of the shape we expect" do
      add_postcodes("SE1 7EZ")
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "ASSR999999",
        valid_assessor_with_contact_request_body,
      )

      response = assessors_search("SE17EZ", "domesticRdSap")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]).to include("assessors")
    end

    it "has the over all hash of the shape we expect" do
      add_postcodes("SE1 7EZ")

      scheme_id = add_scheme_and_get_id

      add_assessor(
        scheme_id,
        "ASSR999999",
        valid_assessor_with_contact_request_body,
      )

      response = assessors_search("SE17EZ", "domesticRdSap")

      response_json = JSON.parse(response.body)

      expected_response =
        JSON.parse(
          {
            firstName: "Some",
            lastName: "Person",
            middleNames: "Middle",
            registeredBy: {
              name: "test scheme",
              schemeId: 25,
            },
            schemeAssessorId: "ASSR999999",
            searchResultsComparisonPostcode: "SE1 7EZ",
            contactDetails: {
              telephoneNumber: "010199991010101",
              email: "person@person.com",
            },
            qualifications: {
              domesticSap: "INACTIVE",
              domesticRdSap: "ACTIVE",
              nonDomesticSp3: "INACTIVE",
              nonDomesticCc4: "INACTIVE",
              nonDomesticDec: "INACTIVE",
              nonDomesticNos3: "INACTIVE",
              nonDomesticNos4: "INACTIVE",
              nonDomesticNos5: "INACTIVE",
              gda: "INACTIVE",
            },
            distanceFromPostcodeInMiles: 0.0,
          }.to_json,
        )

      response_json["data"]["assessors"][0]["registeredBy"]["schemeId"] = 25

      expect(response_json["data"]["assessors"][0]).to eq(expected_response)
    end

    it "does not show assessors outside of 1 degree latitude/longitude" do
      add_postcodes("SE1 9SG", 51.5045, 0.0865)
      add_postcodes("NE8 2BH", 54.9680, 1.6062, false)
      scheme_id = add_scheme_and_get_id
      assessor = valid_assessor_with_contact_request_body
      assessor[:searchResultsComparisonPostcode] = "NE8 2BH"
      add_assessor(
        scheme_id,
        "ASSR999999",
        valid_assessor_with_contact_request_body,
      )

      response = assessors_search("SE19SG", "domesticRdSap")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].size).to eq(0)
    end

    it "shows distance of assessors inside of 1 degree latitude/longitude" do
      add_postcodes("SE1 9SG", 51.5045, 0.0865)

      add_postcodes("SW8 5BN", 51.4818, 0.1444, false)

      scheme_id = add_scheme_and_get_id

      assessor = valid_assessor_with_contact_request_body
      assessor[:searchResultsComparisonPostcode] = "SW8 5BN"
      add_assessor(
        scheme_id,
        "ASSR999999",
        valid_assessor_with_contact_request_body,
      )

      response = assessors_search("SE19SG", "domesticRdSap")

      response_json = JSON.parse(response.body)
      expect(
        response_json["data"]["assessors"][0]["distanceFromPostcodeInMiles"],
      ).to be_between(2, 4)
    end

    it "does not return inactive assessors" do
      add_postcodes("SE1 5BN", 51.5045, 0.0865)

      scheme_id = add_scheme_and_get_id

      assessor = valid_assessor_with_contact_request_body
      assessor[:qualifications][:domesticRdSap] = "INACTIVE"
      add_assessor(
        scheme_id,
        "ASSR999999",
        valid_assessor_with_contact_request_body,
      )
      response = assessors_search("SE15BN", "domesticRdSap")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"]).to eq([])
    end

    it "does return reactivated assessors" do
      add_postcodes("SE1 7EZ", 51.5045, 0.0865)

      scheme_id = add_scheme_and_get_id

      assessor = valid_assessor_with_contact_request_body
      assessor[:qualifications][:domesticRdSap] = "INACTIVE"

      add_assessor(
        scheme_id,
        "ASSR999999",
        valid_assessor_with_contact_request_body,
      )
      assessor[:qualifications][:domesticRdSap] = "ACTIVE"

      add_assessor(
        scheme_id,
        "ASSR999999",
        valid_assessor_with_contact_request_body,
      )

      response = assessors_search("SE17EZ", "domesticRdSap")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].size).to eq(1)
    end

    it "does not return unactivated assessors" do
      add_postcodes("SE1 7EZ", 51.5045, 0.0865)
      scheme_id = add_scheme_and_get_id

      assessor = valid_assessor_with_contact_request_body
      assessor[:qualifications][:domesticRdSap] = "ACTIVE"

      add_assessor(
        scheme_id,
        "ASSR999999",
        valid_assessor_with_contact_request_body,
      )

      assessor[:qualifications][:domesticRdSap] = "INACTIVE"
      add_assessor(
        scheme_id,
        "ASSR999999",
        valid_assessor_with_contact_request_body,
      )

      response = assessors_search("SE17EZ", "domesticRdSap")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].size).to eq(0)
    end

    context "when the postcode is not found" do
      it "returns results based on the outcode of the postcode" do
        add_postcodes("SE1 5BN", 51.5045, 0.0865)
        add_outcodes("SE1", 51.5045, 0.4865)
        scheme_id = add_scheme_and_get_id

        assessor = valid_assessor_with_contact_request_body
        assessor[:searchResultsComparisonPostcode] = "SE1 5BN"
        add_assessor(
          scheme_id,
          "ASSR999999",
          valid_assessor_with_contact_request_body,
        )
        response = assessors_search("SE19SY", "domesticRdSap")

        response_json = JSON.parse(response.body)
        expect(response_json["data"]["assessors"][0]).to include(
          "distanceFromPostcodeInMiles",
        )
      end

      it "returns error when neither postcode or outcode are found" do
        add_postcodes("SE1 5BN", 51.5045, 0.0865)
        add_outcodes("SE1", 51.5045, 0.4865)
        scheme_id = add_scheme_and_get_id

        assessor = valid_assessor_with_contact_request_body
        assessor[:searchResultsComparisonPostcode] = "SE1 5BN"
        add_assessor(
          scheme_id,
          "ASSR999999",
          valid_assessor_with_contact_request_body,
        )
        response = assessors_search("NE19SY", "domesticRdSap", [404])
        response_json = JSON.parse(response.body)
        expect(response_json.key?("errors")).to eq(true)
      end
    end
  end

  context "when searching by qualification" do
    context "for domestic sap assessors" do
      it "returns only the assessors qualified" do
        add_postcodes("SE1 7EZ", 51.5045, 0.0865)
        scheme_id = add_scheme_and_get_id

        sap_assessor = valid_assessor_with_contact_request_body.dup
        sap_assessor[:qualifications][:domesticSap] = "ACTIVE"
        sap_assessor[:qualifications][:domesticRdSap] = "INACTIVE"
        add_assessor(scheme_id, "SAP_123456", sap_assessor)

        rdsap_assessor = valid_assessor_with_contact_request_body.dup
        rdsap_assessor[:qualifications][:domesticSap] = "INACTIVE"
        rdsap_assessor[:qualifications][:domesticRdSap] = "ACTIVE"
        add_assessor(scheme_id, "RDS_654321", rdsap_assessor)

        response = assessors_search("SE17EZ", "domesticSap")
        response_json = JSON.parse(response.body)
        expect(response_json["data"]["assessors"].length).to eq(1)
        expect(
          response_json["data"]["assessors"].first["schemeAssessorId"],
        ).to eq("SAP_123456")
        expect(
          response_json["data"]["assessors"].first["qualifications"][
            "domesticSap"
          ],
        ).to eq("ACTIVE")
      end
    end

    context "for air conditioning level 3 assessors" do
      it "returns only the assessors qualified" do
        add_postcodes("SE1 7EZ", 51.5045, 0.0865)
        scheme_id = add_scheme_and_get_id

        assessor = valid_assessor_with_contact_request_body
        assessor[:qualifications][:domesticRdSap] = "INACTIVE"
        assessor[:qualifications][:nonDomesticSp3] = "ACTIVE"
        add_assessor(scheme_id, "AC__123456", assessor)

        assessor[:qualifications][:domesticRdSap] = "ACTIVE"
        assessor[:qualifications][:nonDomesticSp3] = "INACTIVE"
        add_assessor(scheme_id, "RDS_654321", assessor)

        response = assessors_search("SE17EZ", "nonDomesticSp3")
        response_json = JSON.parse(response.body)
        expect(response_json["data"]["assessors"].length).to eq(1)
        expect(
          response_json["data"]["assessors"].first["schemeAssessorId"],
        ).to eq("AC__123456")
        expect(
          response_json["data"]["assessors"].first["qualifications"][
            "nonDomesticSp3"
          ],
        ).to eq("ACTIVE")
      end
    end

    context "for non domestic dec assessors" do
      it "returns only the assessors qualified" do
        add_postcodes("SE1 7EZ", 51.5045, 0.0865)
        scheme_id = add_scheme_and_get_id

        dec_assessor = valid_assessor_with_contact_request_body.dup
        dec_assessor[:qualifications][:nonDomesticDec] = "ACTIVE"
        dec_assessor[:qualifications][:domesticRdSap] = "INACTIVE"
        add_assessor(scheme_id, "DEC_123456", dec_assessor)

        rdsap_assessor = valid_assessor_with_contact_request_body.dup
        rdsap_assessor[:qualifications][:nonDomesticDec] = "INACTIVE"
        rdsap_assessor[:qualifications][:domesticRdSap] = "ACTIVE"
        add_assessor(scheme_id, "RDS_654321", rdsap_assessor)

        response = assessors_search("SE17EZ", "nonDomesticDec")
        response_json = JSON.parse(response.body)
        expect(response_json["data"]["assessors"].length).to eq(1)
        expect(
          response_json["data"]["assessors"].first["schemeAssessorId"],
        ).to eq("DEC_123456")
        expect(
          response_json["data"]["assessors"].first["qualifications"][
            "nonDomesticDec"
          ],
        ).to eq("ACTIVE")
      end
    end

    context "for non domestic level 3 assessors" do
      it "returns only the assessors qualified" do
        add_postcodes("SE1 7EZ", 51.5045, 0.0865)
        scheme_id = add_scheme_and_get_id

        nos3_assessor = valid_assessor_with_contact_request_body.dup
        nos3_assessor[:qualifications][:nonDomesticNos3] = "ACTIVE"
        nos3_assessor[:qualifications][:domesticRdSap] = "INACTIVE"
        add_assessor(scheme_id, "NOS_123456", nos3_assessor)

        rdsap_assessor = valid_assessor_with_contact_request_body.dup
        rdsap_assessor[:qualifications][:nonDomesticNos3] = "INACTIVE"
        rdsap_assessor[:qualifications][:domesticRdSap] = "ACTIVE"
        add_assessor(scheme_id, "RDS_654321", rdsap_assessor)

        response = assessors_search("SE17EZ", "nonDomesticNos3")
        response_json = JSON.parse(response.body)
        expect(response_json["data"]["assessors"].length).to eq(1)
        expect(
          response_json["data"]["assessors"].first["schemeAssessorId"],
        ).to eq("NOS_123456")
        expect(
          response_json["data"]["assessors"].first["qualifications"][
            "nonDomesticNos3"
          ],
        ).to eq("ACTIVE")
      end
    end

    context "for non domestic level 4 assessors" do
      it "returns only the assessors qualified" do
        add_postcodes("SE1 7EZ", 51.5045, 0.0865)
        scheme_id = add_scheme_and_get_id

        nos4_assessor = valid_assessor_with_contact_request_body.dup
        nos4_assessor[:qualifications][:nonDomesticNos4] = "ACTIVE"
        nos4_assessor[:qualifications][:domesticRdSap] = "INACTIVE"
        add_assessor(scheme_id, "NOS_123456", nos4_assessor)

        rdsap_assessor = valid_assessor_with_contact_request_body.dup
        rdsap_assessor[:qualifications][:nonDomesticNos4] = "INACTIVE"
        rdsap_assessor[:qualifications][:domesticRdSap] = "ACTIVE"
        add_assessor(scheme_id, "RDS_654321", rdsap_assessor)

        response = assessors_search("SE17EZ", "nonDomesticNos4")
        response_json = JSON.parse(response.body)
        expect(response_json["data"]["assessors"].length).to eq(1)
        expect(
          response_json["data"]["assessors"].first["schemeAssessorId"],
        ).to eq("NOS_123456")
        expect(
          response_json["data"]["assessors"].first["qualifications"][
            "nonDomesticNos4"
          ],
        ).to eq("ACTIVE")
      end
    end

    context "for non domestic level 5 assessors" do
      it "returns only the assessors qualified" do
        add_postcodes("SE1 7EZ", 51.5045, 0.0865)
        scheme_id = add_scheme_and_get_id

        nos5_assessor = valid_assessor_with_contact_request_body.dup
        nos5_assessor[:qualifications][:nonDomesticNos5] = "ACTIVE"
        nos5_assessor[:qualifications][:domesticRdSap] = "INACTIVE"
        add_assessor(scheme_id, "NOS_123456", nos5_assessor)

        rdsap_assessor = valid_assessor_with_contact_request_body.dup
        rdsap_assessor[:qualifications][:nonDomesticNos5] = "INACTIVE"
        rdsap_assessor[:qualifications][:domesticRdSap] = "ACTIVE"
        add_assessor(scheme_id, "RDS_654321", rdsap_assessor)

        response = assessors_search("SE17EZ", "nonDomesticNos5")
        response_json = JSON.parse(response.body)
        expect(response_json["data"]["assessors"].length).to eq(1)
        expect(
          response_json["data"]["assessors"].first["schemeAssessorId"],
        ).to eq("NOS_123456")
        expect(
          response_json["data"]["assessors"].first["qualifications"][
            "nonDomesticNos5"
          ],
        ).to eq("ACTIVE")
      end
    end

    context "for multiple types of qualification" do
      it "returns each of the assessors with matching qualifications" do
        add_postcodes("SE1 7EZ", 51.5045, 0.0865)
        scheme_id = add_scheme_and_get_id

        assessor = valid_assessor_with_contact_request_body
        assessor[:qualifications][:nonDomesticSp3] = "ACTIVE"
        assessor[:qualifications][:nonDomesticCc4] = "INACTIVE"
        add_assessor(scheme_id, "AIR_123456", assessor)

        assessor[:qualifications][:nonDomesticSp3] = "INACTIVE"
        assessor[:qualifications][:nonDomesticCc4] = "ACTIVE"
        add_assessor(scheme_id, "COMP654321", assessor)

        response = assessors_search("SE17EZ", "nonDomesticSp3,nonDomesticCc4")
        response_json = JSON.parse(response.body)
        returned_assessor_ids =
          response_json["data"]["assessors"].map { |a| a["schemeAssessorId"] }
        expect(returned_assessor_ids).to contain_exactly(
          "AIR_123456",
          "COMP654321",
        )
      end
    end
  end

  context "when assessors are on an inactive scheme" do
    it "does not return them" do
      add_postcodes("SE1 7EZ")
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "ASSR999999",
        valid_assessor_with_contact_request_body,
      )
      update_scheme(scheme_id, { name: "Old scheme", active: false })
      response = assessors_search("SE1 7EZ", "domesticRdSap")
      response_json = JSON.parse(response.body)
      expect(response_json["data"]["assessors"].size).to eq(0)
    end
  end

  context "security" do
    it "returns a 401 when not authenticated" do
      assessors_search("SE1 7EZ", "domesticRdSap", [401], false)
    end
    it "returns a 403 when the right scopes are not present" do
      assessors_search(
        "SE1 7EZ",
        "domesticRdSap",
        [403],
        true,
        {},
        %w[wrong:scope],
      )
    end
  end
end
