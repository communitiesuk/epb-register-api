VALID_ASSESSOR_REQUEST_BODY = {
  firstName: "Someone",
  middleNames: "Muddle",
  lastName: "Person",
  dateOfBirth: "1991-02-25",
  searchResultsComparisonPostcode: "",
  qualifications: { domesticRdSap: "ACTIVE" },
  contactDetails: {
    telephoneNumber: "010199991010101", email: "person@person.com"
  },
}.freeze

VALID_RDSAP_XML = File.read File.join Dir.pwd, "spec/fixtures/samples/rdsap.xml"
