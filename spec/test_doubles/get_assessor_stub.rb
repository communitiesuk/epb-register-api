class GetAssessorStub
  def fetch_request_body(
    nonDomesticNos3: "SUSPENDED",
    nonDomesticNos4: "SUSPENDED",
    nonDomesticNos5: "SUSPENDED",
    nonDomesticDec: "SUSPENDED",
    domesticRdSap: "SUSPENDED",
    domesticSap: "SUSPENDED",
    nonDomesticSp3: "SUSPENDED",
    nonDomesticCc4: "SUSPENDED",
    gda: "SUSPENDED"
  )
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: {
        nonDomesticNos3: nonDomesticNos3,
        nonDomesticNos4: nonDomesticNos4,
        nonDomesticNos5: nonDomesticNos5,
        nonDomesticDec: nonDomesticDec,
        domesticRdSap: domesticRdSap,
        domesticSap: domesticSap,
        nonDomesticSp3: nonDomesticSp3,
        nonDomesticCc4: nonDomesticCc4,
        gda: gda,
      },
      contactDetails: {
        telephoneNumber: "010199991010101", email: "person@person.com"
      },
    }
  end
end
