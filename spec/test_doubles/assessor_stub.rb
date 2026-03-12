class AssessorStub
  def fetch_request_body(
    non_domestic_nos3: "INACTIVE",
    non_domestic_nos4: "INACTIVE",
    non_domestic_nos5: "INACTIVE",
    non_domestic_dec: "INACTIVE",
    domestic_rd_sap: "INACTIVE",
    domestic_sap: "INACTIVE",
    non_domestic_sp3: "INACTIVE",
    non_domestic_cc4: "INACTIVE",
    gda: "INACTIVE",
    scotland_dec_and_ar: "INACTIVE",
    scotland_nondomestic_existing_building: "INACTIVE",
    scotland_nondomestic_new_building: "INACTIVE",
    scotland_rdsap: "INACTIVE",
    scotland_sap_existing_building:"INACTIVE",
    scotland_sap_new_building: "INACTIVE",
    scotland_section63: "INACTIVE",
    first_name: "Someone",
    middle_names: "Muddle",
    last_name: "Person",
    date_of_birth: "1991-02-25",
    search_results_comparison_postcode: "AB1 0AA"
  )
    {
      firstName: first_name,
      middleNames: middle_names,
      lastName: last_name,
      dateOfBirth: date_of_birth,
      searchResultsComparisonPostcode: search_results_comparison_postcode,
      qualifications: {
        nonDomesticNos3: non_domestic_nos3,
        nonDomesticNos4: non_domestic_nos4,
        nonDomesticNos5: non_domestic_nos5,
        nonDomesticDec: non_domestic_dec,
        domesticRdSap: domestic_rd_sap,
        domesticSap: domestic_sap,
        nonDomesticSp3: non_domestic_sp3,
        nonDomesticCc4: non_domestic_cc4,
        gda:,
        scotlandDecAndAr: scotland_dec_and_ar,
        scotlandNondomesticExistingBuilding: scotland_nondomestic_existing_building,
        scotlandNondomesticNewBuilding: scotland_nondomestic_new_building,
        scotlandRdsap: scotland_rdsap,
        scotlandSapExistingBuilding: scotland_sap_existing_building,
        scotlandSapNewBuilding: scotland_sap_new_building,
        scotlandSection63: scotland_section63,
      },
      contactDetails: {
        telephoneNumber: "010199991010101",
        email: "person@person.com",
      },
    }

  end
end
