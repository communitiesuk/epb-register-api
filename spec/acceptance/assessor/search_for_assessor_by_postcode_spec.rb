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
      searchResultsComparisonPostcode: "SW1A 2AA",
      qualifications: {
        domestic_rd_sap: "ACTIVE",
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
        scotland_rdsap: "INACTIVE",
        scotland_sap_existing: "INACTIVE",
        scotland_sap_new_building: "INACTIVE",
        scotland_section63: "INACTIVE",
      },
    }
  end
  let(:scheme_id) { add_scheme_and_get_id }

  before do
    add_postcodes("SW1A 2AA", 51.503541, -0.12767, "London")
    add_assessor scheme_id:,
                 assessor_id: "ASSR999999",
                 body: valid_assessor_with_contact_request_body
  end

  context "when searching without the right params" do
    it "returns status 404 when the postcode is in an incorrect format" do
      expect(assessors_search(postcode: "73334", qualification: "domesticRdSap", accepted_responses: [404]).status).to eq(404)
    end

    it "returns a 400 for postcode search without qualification" do
      expect(assertive_get(
        "api/assessors?postcode=SW1A 2AA",
        accepted_responses: [400],
        scopes: %w[assessor:search],
      ).status).to eq 400
    end

    it "returns a 400 or no parameters" do
      expect(assertive_get(
        "/api/assessors",
        accepted_responses: [400],
        scopes: %w[assessor:search],
      ).status).to eq 400
    end

    it "rejects a request which searches for a non-existent qualification" do
      expect(assessors_search(postcode: "SW1A 2AA", qualification: "doubleGlazingFitter", accepted_responses: [400]).status).to eq 400
    end

    it "returns an error when searching for a scottish qualification type" do
      scottish_assessor = valid_assessor_with_contact_request_body
      scottish_assessor[:qualifications][:scotland_rdsap] = "ACTIVE"
      add_assessor scheme_id:,
                   assessor_id: "ASSR299999",
                   body: scottish_assessor

      response = assessors_search(postcode: "SW1A 2AA", qualification: "scotlandRdsap", accepted_responses: [400])
      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "Unrecognised qualification type"
    end

    context "when a scottish postcode (not on the border) is requested" do
      before do
        add_postcodes("EH8 8FT", 55.9519, 3.1823, "Scotland")
        add_outcodes("EH8", 55.94995568352805, -3.166325968871591, "Scotland")
        assessor = valid_assessor_with_contact_request_body
        assessor[:searchResultsComparisonPostcode] = "EH8 8FT"
        add_assessor(
          scheme_id:,
          assessor_id: "ASSR999292",
          body: assessor,
        )
      end

      it "returns an error" do
        expect(assessors_search(postcode: "EH8 8FT", qualification: "domesticRdSap", accepted_responses: [404]).status).to eq(404)
      end
    end
  end

  context "when a search postcode is valid" do
    it "returns qualified assessors in the search area" do
      response = assessors_search(postcode: "SW1A 2AA", qualification: "domesticRdSap")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].length).to eq 1
    end

    it "allows searching using a postcode with excessive spaces" do
      response = assessors_search(postcode: "  SW1A 2AA   ", qualification: "domesticRdSap")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].length).to eq 1
    end

    it "allows searching using a postcode with no spaces" do
      response = assessors_search(postcode: "SW1A2AA", qualification: "domesticRdSap")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].length).to eq 1
    end

    it "allows searching using a lowercase postcode" do
      response = assessors_search(postcode: "sw1a 2aa", qualification: "domesticRdSap")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessors"].length).to eq 1
    end

    it "has the properties we expect" do
      response = assessors_search(postcode: "SW1A2AA", qualification: "domesticRdSap")
      response_json = JSON.parse(response.body)

      expect(response_json).to include("data", "meta")
    end

    it "has the assessors of the shape we expect" do
      response = assessors_search(postcode: "SW1A2AA", qualification: "domesticRdSap")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]).to include("assessors")
    end

    it "has the over all hash of the shape we expect" do
      response = assessors_search(postcode: "SW1A2AA", qualification: "domesticRdSap")

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
            searchResultsComparisonPostcode: "SW1A 2AA",
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
              scotlandDecAndAr: "INACTIVE",
              scotlandNondomesticExistingBuilding: "INACTIVE",
              scotlandNondomesticNewBuilding: "INACTIVE",
              scotlandRdsap: "INACTIVE",
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
      add_postcodes("NE8 2BH", 54.9680, 1.6062, "North East")
      assessor = valid_assessor_with_contact_request_body
      assessor[:searchResultsComparisonPostcode] = "NE8 2BH"
      add_assessor(
        scheme_id:,
        assessor_id: "ASSR999991",
        body: valid_assessor_with_contact_request_body,
      )

      response = assessors_search(postcode: "SW1A2AA", qualification: "domesticRdSap")
      response_json = JSON.parse(response.body)
      assessor_result = response_json["data"]["assessors"]

      expect(assessor_result.any? { |h| h["searchResultsComparisonPostcode"] == "SW1A 2AA" }).to be true
      expect(assessor_result.any? { |h| h["searchResultsComparisonPostcode"] == "NE8 2BH" }).to be false
    end

    it "shows distance of assessors inside of 1 degree latitude/longitude" do
      add_postcodes("SW8 5BN", 51.4818, 0.1444, "London")
      assessor = valid_assessor_with_contact_request_body
      assessor[:searchResultsComparisonPostcode] = "SW8 5BN"
      add_assessor(
        scheme_id:,
        assessor_id: "ASSR999991",
        body: valid_assessor_with_contact_request_body,
      )

      response = assessors_search(postcode: "SW1A2AA", qualification: "domesticRdSap")
      response_json = JSON.parse(response.body)
      assessor_result = response_json["data"]["assessors"]

      expect(assessor_result.any? { |h| h["searchResultsComparisonPostcode"] == "SW1A 2AA" }).to be true
      expect(assessor_result.any? { |h| h["searchResultsComparisonPostcode"] == "SW8 5BN" }).to be true
    end

    it "does not return inactive assessors" do
      assessor = valid_assessor_with_contact_request_body
      assessor[:qualifications][:domesticRdSap] = "INACTIVE"
      add_assessor(
        scheme_id:,
        assessor_id: "ASSR999991",
        body: valid_assessor_with_contact_request_body,
      )
      response = assessors_search(postcode: "SW1A 2AA", qualification: "domesticRdSap")
      response_json = JSON.parse(response.body)
      assessor_result = response_json["data"]["assessors"]

      expect(assessor_result.any? { |h| h["schemeAssessorId"] == "ASSR999999" }).to be true
      expect(assessor_result.any? { |h| h["schemeAssessorId"] == "ASSR999991" }).to be false
    end

    context "when the postcode is not found" do
      before do
        add_outcodes("SW1A", 51.50197821468924, -0.13386012429378527, "London")
      end

      it "returns results based on the outcode of the postcode" do
        response = assessors_search(postcode: "SW1A 2RE", qualification: "domesticRdSap")

        response_json = JSON.parse(response.body)
        expect(response_json["data"]["assessors"].length).to eq 1
      end

      it "returns error when neither postcode or outcode are found" do
        expect(assessors_search(postcode: "NE19SY", qualification: "domesticRdSap", accepted_responses: [404]).status)
          .to eq(404)
      end

      context "when the postcode is on the list of BORDER_OUTCODES" do
        before do
          add_outcodes("DG14", 55.0801214642857, -2.9875917261904763, "Scotland")
        end

        it "returns results based on the outcode of the postcode" do
          assessor = valid_assessor_with_contact_request_body
          assessor[:searchResultsComparisonPostcode] = "DG14 1DQ"
          add_assessor(
            scheme_id:,
            assessor_id: "ASSR999292",
            body: assessor,
          )
          response = assessors_search(postcode: "DG14 2RE", qualification: "domesticRdSap")

          response_json = JSON.parse(response.body)
          expect(response_json["data"]["assessors"].length).to eq 1
        end
      end
    end

    context "when searching for a postcode on the border" do
      before do
        add_postcodes("DG14 0TF", 55.056368, -2.958697, "Scotland")
        add_postcodes("DG1 1DQ", 55.070518, -3.611893, "Scotland")
      end

      it "returns assessors based in Scotland with the correct qualification" do
        assessor = valid_assessor_with_contact_request_body
        assessor[:searchResultsComparisonPostcode] = "DG1 1DQ"
        add_assessor(
          scheme_id:,
          assessor_id: "ASSR999292",
          body: assessor,
        )
        response = assessors_search(postcode: "DG14 0TF", qualification: "domesticRdSap")
        response_json = JSON.parse(response.body)

        expect(response_json["data"]["assessors"].length).to eq(1)
      end

      context "when the postcode is not in the database" do
        before do
          add_outcodes("TD5 7AA,55.599452,-2.431652,Scotland")
          add_outcodes("TD5", 55.589470939508615, -2.419147277882796, "Scotland")
          assessor = valid_assessor_with_contact_request_body
          assessor[:searchResultsComparisonPostcode] = "TD5 7AA"
          add_assessor(
            scheme_id:,
            assessor_id: "ASSR999291",
            body: assessor,
          )
        end

        it "returns an assessor if the outcode is on the list of SCOTTISH_BORDER_OUTCODES" do
          response = assessors_search(postcode: "TD5 0TU", qualification: "domesticRdSap")
          response_json = JSON.parse(response.body)

          expect(response_json["data"]["assessors"].length).to eq(1)
        end
      end
    end
  end

  context "when searching by qualification" do
    context "when searching domestic sap assessors" do
      it "returns only the assessors qualified" do
        sap_assessor = valid_assessor_with_contact_request_body.dup
        sap_assessor[:qualifications][:domesticSap] = "ACTIVE"
        sap_assessor[:qualifications][:domesticRdSap] = "INACTIVE"
        add_assessor(scheme_id:, assessor_id: "SAP_123456", body: sap_assessor)

        response = assessors_search(postcode: "SW1A 2AA", qualification: "domesticSap")
        response_json = JSON.parse(response.body)

        expect(response_json["data"]["assessors"].length).to eq(1)
        expect(
          response_json["data"]["assessors"].first["schemeAssessorId"],
        ).to eq("SAP_123456")
        expect(
          response_json["data"]["assessors"].first["qualifications"][
            "domesticSap",
          ],
        ).to eq("ACTIVE")
      end
    end

    context "when searching air conditioning level 3 assessors" do
      it "returns only the assessors qualified" do
        assessor = valid_assessor_with_contact_request_body
        assessor[:qualifications][:domesticRdSap] = "INACTIVE"
        assessor[:qualifications][:nonDomesticSp3] = "ACTIVE"
        add_assessor(scheme_id:, assessor_id: "AC__123456", body: assessor)

        response = assessors_search(postcode: "SW1A 2AA", qualification: "nonDomesticSp3")
        response_json = JSON.parse(response.body)

        expect(response_json["data"]["assessors"].length).to eq(1)
        expect(
          response_json["data"]["assessors"].first["schemeAssessorId"],
        ).to eq("AC__123456")
        expect(
          response_json["data"]["assessors"].first["qualifications"][
            "nonDomesticSp3",
          ],
        ).to eq("ACTIVE")
      end
    end

    context "when searching non domestic dec assessors" do
      it "returns only the assessors qualified" do
        dec_assessor = valid_assessor_with_contact_request_body.dup
        dec_assessor[:qualifications][:nonDomesticDec] = "ACTIVE"
        dec_assessor[:qualifications][:domesticRdSap] = "INACTIVE"
        add_assessor(scheme_id:, assessor_id: "DEC_123456", body: dec_assessor)

        response = assessors_search(postcode: "SW1A 2AA", qualification: "nonDomesticDec")
        response_json = JSON.parse(response.body)

        expect(response_json["data"]["assessors"].length).to eq(1)
        expect(
          response_json["data"]["assessors"].first["schemeAssessorId"],
        ).to eq("DEC_123456")
        expect(
          response_json["data"]["assessors"].first["qualifications"][
            "nonDomesticDec",
          ],
        ).to eq("ACTIVE")
      end
    end

    context "when searching non domestic level 3 assessors" do
      it "returns only the assessors qualified" do
        nos3_assessor = valid_assessor_with_contact_request_body.dup
        nos3_assessor[:qualifications][:nonDomesticNos3] = "ACTIVE"
        nos3_assessor[:qualifications][:domesticRdSap] = "INACTIVE"
        add_assessor(scheme_id:, assessor_id: "NOS_123456", body: nos3_assessor)

        response = assessors_search(postcode: "SW1A 2AA", qualification: "nonDomesticNos3")
        response_json = JSON.parse(response.body)
        expect(response_json["data"]["assessors"].length).to eq(1)
        expect(
          response_json["data"]["assessors"].first["schemeAssessorId"],
        ).to eq("NOS_123456")
        expect(
          response_json["data"]["assessors"].first["qualifications"][
            "nonDomesticNos3",
          ],
        ).to eq("ACTIVE")
      end
    end

    context "when searching non domestic level 4 assessors" do
      it "returns only the assessors qualified" do
        nos4_assessor = valid_assessor_with_contact_request_body.dup
        nos4_assessor[:qualifications][:nonDomesticNos4] = "ACTIVE"
        nos4_assessor[:qualifications][:domesticRdSap] = "INACTIVE"
        add_assessor(scheme_id:, assessor_id: "NOS_123456", body: nos4_assessor)

        response = assessors_search(postcode: "SW1A 2AA", qualification: "nonDomesticNos4")
        response_json = JSON.parse(response.body)

        expect(response_json["data"]["assessors"].length).to eq(1)
        expect(
          response_json["data"]["assessors"].first["schemeAssessorId"],
        ).to eq("NOS_123456")
        expect(
          response_json["data"]["assessors"].first["qualifications"][
            "nonDomesticNos4",
          ],
        ).to eq("ACTIVE")
      end
    end

    context "when searching non domestic level 5 assessors" do
      it "returns only the assessors qualified" do
        nos5_assessor = valid_assessor_with_contact_request_body.dup
        nos5_assessor[:qualifications][:nonDomesticNos5] = "ACTIVE"
        nos5_assessor[:qualifications][:domesticRdSap] = "INACTIVE"
        add_assessor(scheme_id:, assessor_id: "NOS_123456", body: nos5_assessor)

        response = assessors_search(postcode: "SW1A 2AA", qualification: "nonDomesticNos5")
        response_json = JSON.parse(response.body)
        expect(response_json["data"]["assessors"].length).to eq(1)
        expect(
          response_json["data"]["assessors"].first["schemeAssessorId"],
        ).to eq("NOS_123456")
        expect(
          response_json["data"]["assessors"].first["qualifications"][
            "nonDomesticNos5",
          ],
        ).to eq("ACTIVE")
      end
    end

    context "when searching multiple types of qualification" do
      it "returns each of the assessors with matching qualifications" do
        assessor = valid_assessor_with_contact_request_body
        assessor[:qualifications][:nonDomesticSp3] = "ACTIVE"
        assessor[:qualifications][:nonDomesticCc4] = "INACTIVE"
        add_assessor(scheme_id:, assessor_id: "AIR_123456", body: assessor)

        assessor[:qualifications][:nonDomesticSp3] = "INACTIVE"
        assessor[:qualifications][:nonDomesticCc4] = "ACTIVE"
        add_assessor(scheme_id:, assessor_id: "COMP654321", body: assessor)

        response = assessors_search(postcode: "SW1A 2AA", qualification: "nonDomesticSp3,nonDomesticCc4")
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
      update_scheme(scheme_id:, body: { name: "Old scheme", active: false })
      response = assessors_search(postcode: "SW1A 2AA", qualification: "domesticRdSap")
      response_json = JSON.parse(response.body)
      expect(response_json["data"]["assessors"]).to eq []
    end
  end

  describe "security scenarios" do
    it "returns a 401 when not authenticated" do
      expect(assessors_search(
        postcode: "SW1A 2AA",
        qualification: "domesticRdSap",
        accepted_responses: [401],
        should_authenticate: false,
      ).status).to eq 401
    end

    it "returns a 403 when the right scopes are not present" do
      expect(assessors_search(
        postcode: "SW1A 2AA",
        qualification: "domesticRdSap",
        accepted_responses: [403],
        scopes: %w[wrong:scope],
      ).status).to eq 403
    end
  end
end
