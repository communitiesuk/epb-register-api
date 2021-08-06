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
    first_name: "Someone",
    middle_names: "Muddle",
    last_name: "Person",
    date_of_birth: "1991-02-25"
  )
    {
      firstName: first_name,
      middleNames: middle_names,
      lastName: last_name,
      dateOfBirth: date_of_birth,
      searchResultsComparisonPostcode: "",
      qualifications: {
        nonDomesticNos3: non_domestic_nos3,
        nonDomesticNos4: non_domestic_nos4,
        nonDomesticNos5: non_domestic_nos5,
        nonDomesticDec: non_domestic_dec,
        domesticRdSap: domestic_rd_sap,
        domesticSap: domestic_sap,
        nonDomesticSp3: non_domestic_sp3,
        nonDomesticCc4: non_domestic_cc4,
        gda: gda,
      },
      contactDetails: {
        telephoneNumber: "010199991010101",
        email: "person@person.com",
      },
    }
  end
end
