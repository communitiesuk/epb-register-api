describe "Acceptance::ScottishSearchForAssessor" do
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
      searchResultsComparisonPostcode: "EH8 8FT",
      qualifications: {
        domestic_rd_sap: "INACTIVE",
        domestic_sap: "INACTIVE",
        non_domestic_sp3: "INACTIVE",
        non_domestic_cc4: "INACTIVE",
        non_domestic_dec: "INACTIVE",
        non_domestic_nos3: "INACTIVE",
        non_domestic_nos4: "INACTIVE",
        non_domestic_nos5: "INACTIVE",
        gda: "INACTIVE",
        scotland_dec_and_ar: "INACTIVE",
        scotland_nondomestic_existing_building: "INACTIVE",
        scotland_nondomestic_new_building: "INACTIVE",
        scotland_rdsap: "ACTIVE",
        scotland_sap_existing: "INACTIVE",
        scotland_sap_new_building: "INACTIVE",
        scotland_section63: "INACTIVE",
      },
    }
  end

  context "when a search postcode is not found" do
    it "returns status 404 for a get" do
      expect(scotland_assessors_search(postcode: "73334", qualification: "scotlandRdsap", accepted_responses: [404]).status).to eq(404)
    end
  end

  context "when searching without the right params" do
    before do
      add_postcodes("EH8 8FT")
    end

    it "returns a 400 for postcode search without qualification" do
      expect(assertive_get(
        "api/scotland/assessors?postcode=EH88FT",
        accepted_responses: [400],
        scopes: %w[scotland_assessor:search],
      ).status).to eq 400
    end

    it "returns a 400 for no postcode" do
      expect(assertive_get(
        "api/scotland/assessors?qualification=scotlandRdsap",
        accepted_responses: [400],
        scopes: %w[scotland_assessor:search],
      ).status).to eq 400
    end

    it "rejects a request which searches for a bad qualification" do
      add_postcodes("EH8 8FT")
      expect(scotland_assessors_search(postcode: "EH8 8FT", qualification: "doubleGlazingFitter", accepted_responses: [400]).status).to eq 400
    end
  end

  context "when a search postcode is valid" do
    it "allows searching using a normal looking postcode" do
      add_postcodes("EH8 8FT")
      scheme_id = add_scheme_and_get_id
      add_assessor scheme_id:,
                   assessor_id: "ASSR999999",
                   body: valid_assessor_with_contact_request_body

      response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "scotlandRdsap")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].length).to eq 1
    end

    it "searches using an outcode if we dont know the postcode" do
      add_outcodes("EH8")
      scheme_id = add_scheme_and_get_id
      add_assessor scheme_id:,
                   assessor_id: "ASSR999999",
                   body: valid_assessor_with_contact_request_body

      response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "scotlandRdsap")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].length).to eq 1
    end

    it "allows searching using a postcode with excessive spaces" do
      add_postcodes("EH8 8FT")
      scheme_id = add_scheme_and_get_id
      add_assessor scheme_id:,
                   assessor_id: "ASSR999999",
                   body: valid_assessor_with_contact_request_body

      response = scotland_assessors_search(postcode: "  EH8 8FT   ", qualification: "scotlandRdsap")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].length).to eq 1
    end

    it "allows searching using a postcode with no spaces" do
      add_postcodes("EH8 8FT")
      scheme_id = add_scheme_and_get_id
      add_assessor scheme_id:,
                   assessor_id: "ASSR999999",
                   body: valid_assessor_with_contact_request_body

      response = scotland_assessors_search(postcode: "EH88FT", qualification: "scotlandRdsap")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].length).to eq 1
    end

    it "allows searching using a lowercase postcode" do
      add_postcodes("EH8 8FT")
      scheme_id = add_scheme_and_get_id
      add_assessor scheme_id:,
                   assessor_id: "ASSR999999",
                   body: valid_assessor_with_contact_request_body

      response = scotland_assessors_search(postcode: "eh8 8ft", qualification: "scotlandRdsap")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].length).to eq 1
    end

    it "has the properties we expect" do
      add_postcodes("EH8 8FT")

      response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "scotlandRdsap")
      response_json = JSON.parse(response.body)

      expect(response_json).to include("data", "meta")
    end

    it "has the assessors of the shape we expect" do
      add_postcodes("EH8 8FT")
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id:,
        assessor_id: "ASSR999999",
        body: valid_assessor_with_contact_request_body,
      )

      response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "scotlandRdsap")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]).to include("assessors")
    end

    it "has the over all hash of the shape we expect" do
      add_postcodes("EH8 8FT")

      scheme_id = add_scheme_and_get_id

      add_assessor(
        scheme_id:,
        assessor_id: "ASSR999999",
        body: valid_assessor_with_contact_request_body,
      )

      response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "scotlandRdsap")

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
            searchResultsComparisonPostcode: "EH8 8FT",
            contactDetails: {
              telephoneNumber: "010199991010101",
              email: "person@person.com",
            },
            qualifications: {
              domesticSap: "INACTIVE",
              domesticRdSap: "INACTIVE",
              nonDomesticSp3: "INACTIVE",
              nonDomesticCc4: "INACTIVE",
              nonDomesticDec: "INACTIVE",
              nonDomesticNos3: "INACTIVE",
              nonDomesticNos4: "INACTIVE",
              nonDomesticNos5: "INACTIVE",
              gda: "INACTIVE",
              scotlandDecAndAr: "INACTIVE",
              scotlandNondomesticExistingBuilding: "INACTIVE",
              scotlandNondomesticNewBuilding: "INACTIVE",
              scotlandRdsap: "ACTIVE",
              scotlandSapExistingBuilding: "INACTIVE",
              scotlandSapNewBuilding: "INACTIVE",
              scotlandSection63: "INACTIVE",
            },
            distanceFromPostcodeInMiles: 0.0,
          }.to_json,
        )

      response_json["data"]["assessors"][0]["registeredBy"]["schemeId"] = 25
      expect(response_json["data"]["assessors"][0]).to eq(expected_response)
    end

    it "does not show assessors outside of 1 degree latitude/longitude" do
      add_postcodes("EH8 8FT", 55.9519, 3.1823)
      add_postcodes("G2 8LU", 55.8571, 4.2645, false)
      scheme_id = add_scheme_and_get_id
      assessor = valid_assessor_with_contact_request_body
      assessor[:searchResultsComparisonPostcode] = "G2 8LU"
      add_assessor(
        scheme_id:,
        assessor_id: "ASSR999999",
        body: valid_assessor_with_contact_request_body,
      )

      response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "scotlandRdsap")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].size).to eq(0)
    end

    it "shows distance of assessors inside of 1 degree latitude/longitude" do
      add_postcodes("EH8 8FT", 55.9519, 3.1823)
      add_postcodes("EH1 3DG", 55.9537, 3.1839, false)

      scheme_id = add_scheme_and_get_id

      assessor = valid_assessor_with_contact_request_body
      assessor[:searchResultsComparisonPostcode] = "EH1 3DG"
      add_assessor(
        scheme_id:,
        assessor_id: "ASSR999999",
        body: valid_assessor_with_contact_request_body,
      )

      response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "scotlandRdsap")

      response_json = JSON.parse(response.body)
      expect(
        response_json["data"]["assessors"][0]["distanceFromPostcodeInMiles"],
      ).to be_between(0, 1)
    end

    it "doesn't return assessors within the search area with only non-scottish qualifications" do
      add_postcodes("EH8 8FT")
      scheme_id = add_scheme_and_get_id
      english_qualification_assessor = valid_assessor_with_contact_request_body
      english_qualification_assessor[:qualifications][:scotland_rdsap] = "INACTIVE"
      english_qualification_assessor[:qualifications][:domestic_rd_sap] = "ACTIVE"
      add_assessor scheme_id:,
                   assessor_id: "ASSR999999",
                   body: english_qualification_assessor

      response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "domesticRdSap", accepted_responses: [400])
      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "Unrecognised qualification type"
    end

    it "does not return inactive assessors" do
      add_postcodes("EH8 8FT", 55.9519, 3.1823)

      scheme_id = add_scheme_and_get_id

      assessor = valid_assessor_with_contact_request_body
      assessor[:qualifications][:scotland_rdsap] = "INACTIVE"
      add_assessor(
        scheme_id:,
        assessor_id: "ASSR999999",
        body: assessor,
      )
      response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "scotlandRdsap")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"]).to eq([])
    end

    it "does return reactivated assessors" do
      add_postcodes("EH8 8FT", 55.9519, 3.1823)

      scheme_id = add_scheme_and_get_id

      assessor = valid_assessor_with_contact_request_body
      assessor[:qualifications][:scotland_rdsap] = "INACTIVE"
      add_assessor(
        scheme_id:,
        assessor_id: "ASSR999999",
        body: assessor,
      )
      assessor[:qualifications][:scotland_rdsap] = "ACTIVE"

      add_assessor(
        scheme_id:,
        assessor_id: "ASSR999999",
        body: assessor,
      )

      response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "scotlandRdsap")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].size).to eq(1)
    end

    it "does not return inactivated assessors" do
      add_postcodes("EH8 8FT", 55.9519, 3.1823)
      scheme_id = add_scheme_and_get_id

      assessor = valid_assessor_with_contact_request_body

      add_assessor(
        scheme_id:,
        assessor_id: "ASSR999999",
        body: assessor,
      )

      assessor[:qualifications][:scotland_rdsap] = "INACTIVE"
      add_assessor(
        scheme_id:,
        assessor_id: "ASSR999999",
        body: assessor,
      )

      response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "scotlandRdsap")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].size).to eq(0)
    end

    context "when the postcode is not found" do
      it "returns results based on the outcode of the postcode" do
        add_postcodes("EH8 8FT", 55.9519, 3.1823)
        add_outcodes("EH8", 55.9484, 3.1589)
        scheme_id = add_scheme_and_get_id

        assessor = valid_assessor_with_contact_request_body
        assessor[:searchResultsComparisonPostcode] = "EH8 8FT"
        add_assessor(
          scheme_id:,
          assessor_id: "ASSR999999",
          body: assessor,
        )
        response = scotland_assessors_search(postcode: "EH8 8DX", qualification: "scotlandRdsap")

        response_json = JSON.parse(response.body)
        expect(response_json["data"]["assessors"][0]).to include(
          "distanceFromPostcodeInMiles",
        )
      end

      it "returns error when neither postcode or outcode are found" do
        add_postcodes("EH8 8FT", 55.9519, 3.1823)
        add_outcodes("EH8", 55.9484, 3.1589)
        scheme_id = add_scheme_and_get_id

        assessor = valid_assessor_with_contact_request_body
        assessor[:searchResultsComparisonPostcode] = "EH8 8FT"
        add_assessor(
          scheme_id:,
          assessor_id: "ASSR999999",
          body: valid_assessor_with_contact_request_body,
        )
        response = scotland_assessors_search(postcode: "EH99 1SP", qualification: "scotlandRdsap", accepted_responses: [404])
        response_json = JSON.parse(response.body)
        expect(response_json.key?("errors")).to be(true)
      end
    end
  end

  context "when searching by qualification" do
    context "when searching domestic sap new building assessors" do
      it "returns only the assessors qualified" do
        add_postcodes("EH8 8FT", 55.9519, 3.1823)
        scheme_id = add_scheme_and_get_id

        sap_assessor = valid_assessor_with_contact_request_body.dup
        sap_assessor[:qualifications][:scotland_sap_new_building] = "ACTIVE"
        sap_assessor[:qualifications][:scotland_rdsap] = "INACTIVE"
        add_assessor(scheme_id:, assessor_id: "SAP_123456", body: sap_assessor)

        rdsap_assessor = valid_assessor_with_contact_request_body.dup
        rdsap_assessor[:qualifications][:scotland_sap_new_building] = "INACTIVE"
        rdsap_assessor[:qualifications][:scotland_rdsap] = "ACTIVE"
        add_assessor(scheme_id:, assessor_id: "RDS_654321", body: rdsap_assessor)

        response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "scotlandSapNewBuilding")
        response_json = JSON.parse(response.body)
        expect(response_json["data"]["assessors"].length).to eq(1)
        expect(
          response_json["data"]["assessors"].first["schemeAssessorId"],
        ).to eq("SAP_123456")
        expect(
          response_json["data"]["assessors"].first["qualifications"][
            "scotlandSapNewBuilding",
          ],
        ).to eq("ACTIVE")
      end
    end

    context "when searching domestic sap existing building assessors" do
      it "returns only the assessors qualified" do
        add_postcodes("EH8 8FT", 55.9519, 3.1823)
        scheme_id = add_scheme_and_get_id

        sap_assessor = valid_assessor_with_contact_request_body.dup
        sap_assessor[:qualifications][:scotland_sap_existing_building] = "ACTIVE"
        sap_assessor[:qualifications][:scotland_rdsap] = "INACTIVE"
        add_assessor(scheme_id:, assessor_id: "SAP_123456", body: sap_assessor)

        rdsap_assessor = valid_assessor_with_contact_request_body.dup
        rdsap_assessor[:qualifications][:scotland_sap_existing_building] = "INACTIVE"
        rdsap_assessor[:qualifications][:scotland_rdsap] = "ACTIVE"
        add_assessor(scheme_id:, assessor_id: "RDS_654321", body: rdsap_assessor)

        response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "scotlandSapExistingBuilding")
        response_json = JSON.parse(response.body)
        expect(response_json["data"]["assessors"].length).to eq(1)
        expect(
          response_json["data"]["assessors"].first["schemeAssessorId"],
        ).to eq("SAP_123456")
        expect(
          response_json["data"]["assessors"].first["qualifications"][
            "scotlandSapExistingBuilding",
          ],
        ).to eq("ACTIVE")
      end
    end

    context "when searching non domestic dec assessors" do
      it "returns only the assessors qualified" do
        add_postcodes("EH8 8FT", 55.9519, 3.1823)
        scheme_id = add_scheme_and_get_id

        dec_assessor = valid_assessor_with_contact_request_body.dup
        dec_assessor[:qualifications][:scotland_dec_and_ar] = "ACTIVE"
        dec_assessor[:qualifications][:scotland_rdsap] = "INACTIVE"
        add_assessor(scheme_id:, assessor_id: "DEC_123456", body: dec_assessor)

        rdsap_assessor = valid_assessor_with_contact_request_body.dup
        rdsap_assessor[:qualifications][:scotland_dec_and_ar] = "INACTIVE"
        rdsap_assessor[:qualifications][:scotland_rdsap] = "ACTIVE"
        add_assessor(scheme_id:, assessor_id: "RDS_654321", body: rdsap_assessor)

        response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "scotlandDecAndAr")
        response_json = JSON.parse(response.body)
        expect(response_json["data"]["assessors"].length).to eq(1)
        expect(
          response_json["data"]["assessors"].first["schemeAssessorId"],
        ).to eq("DEC_123456")
        expect(
          response_json["data"]["assessors"].first["qualifications"][
            "scotlandDecAndAr",
          ],
        ).to eq("ACTIVE")
      end
    end

    context "when searching Section 63 assessors" do
      it "returns only the assessors qualified" do
        add_postcodes("EH8 8FT", 55.9519, 3.1823)
        scheme_id = add_scheme_and_get_id

        nos3_assessor = valid_assessor_with_contact_request_body.dup
        nos3_assessor[:qualifications][:scotland_section63] = "ACTIVE"
        nos3_assessor[:qualifications][:scotland_rdsap] = "INACTIVE"
        add_assessor(scheme_id:, assessor_id: "NOS_123456", body: nos3_assessor)

        rdsap_assessor = valid_assessor_with_contact_request_body.dup
        rdsap_assessor[:qualifications][:scotland_section63] = "INACTIVE"
        rdsap_assessor[:qualifications][:scotland_rdsap] = "ACTIVE"
        add_assessor(scheme_id:, assessor_id: "RDS_654321", body: rdsap_assessor)

        response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "scotlandSection63")
        response_json = JSON.parse(response.body)
        expect(response_json["data"]["assessors"].length).to eq(1)
        expect(
          response_json["data"]["assessors"].first["schemeAssessorId"],
        ).to eq("NOS_123456")
        expect(
          response_json["data"]["assessors"].first["qualifications"][
            "scotlandSection63",
          ],
        ).to eq("ACTIVE")
      end
    end

    context "when searching multiple types of qualification" do
      it "returns each of the assessors with matching qualifications" do
        add_postcodes("EH8 8FT", 55.9519, 3.1823)
        scheme_id = add_scheme_and_get_id

        assessor = valid_assessor_with_contact_request_body
        assessor[:qualifications][:scotland_section63] = "ACTIVE"
        assessor[:qualifications][:scotland_dec_and_ar] = "INACTIVE"
        add_assessor(scheme_id:, assessor_id: "AIR_123456", body: assessor)

        assessor[:qualifications][:scotland_section63] = "INACTIVE"
        assessor[:qualifications][:scotland_dec_and_ar] = "ACTIVE"
        add_assessor(scheme_id:, assessor_id: "COMP654321", body: assessor)

        response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "scotlandSection63,scotlandDecAndAr")
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
      add_postcodes("EH8 8FT", 55.9519, 3.1823)
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id:,
        assessor_id: "ASSR999999",
        body: valid_assessor_with_contact_request_body,
      )
      update_scheme(scheme_id:, body: { name: "Old scheme", active: false })
      response = scotland_assessors_search(postcode: "EH8 8FT", qualification: "scotlandRdsap")
      response_json = JSON.parse(response.body)
      expect(response_json["data"]["assessors"].size).to eq(0)
    end
  end

  describe "security scenarios" do
    it "returns a 401 when not authenticated" do
      expect(scotland_assessors_search(
        postcode: "EH8 8FT",
        qualification: "scotlandRdsap",
        accepted_responses: [401],
        should_authenticate: false,
      ).status).to eq 401
    end

    it "returns a 403 when the right scopes are not present" do
      expect(scotland_assessors_search(
        postcode: "EH8 8FT",
        qualification: "scotlandRdsap",
        accepted_responses: [403],
        scopes: %w[wrong:scope],
      ).status).to eq 403
    end
  end
end
