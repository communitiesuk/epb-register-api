VALID_ASSESSOR_REQUEST_BODY = {
  firstName: "Someone",
  middleNames: "Muddle",
  lastName: "Person",
  dateOfBirth: "1991-02-25",
  searchResultsComparisonPostcode: "",
  qualifications: {
    domesticRdSap: "ACTIVE",
  },
  contactDetails: {
    telephoneNumber: "010199991010101",
    email: "person@person.com",
  },
}.freeze

class Samples
  def self.xml(schema, type = "epc")
    path = File.join Dir.pwd, "spec/fixtures/samples/#{schema}/#{type}.xml"

    unless File.exist? path
      raise ArgumentError,
            "No #{type} sample found for schema #{schema}, create one at #{
              path
            }"
    end

    File.read path
  end

  def self.update_test_hash(test_hash, args = {})
    hash = test_hash.dup
    hash.merge!(args)
  end
end
