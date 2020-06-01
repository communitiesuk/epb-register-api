class AssessorStub
  def fetch_request_body(
    nonDomesticNos3: "INACTIVE",
    nonDomesticNos4: "INACTIVE",
    nonDomesticNos5: "INACTIVE",
    nonDomesticDec: "INACTIVE",
    domesticRdSap: "INACTIVE",
    domesticSap: "INACTIVE",
    nonDomesticSp3: "INACTIVE",
    nonDomesticCc4: "INACTIVE",
    gda: "INACTIVE"
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
