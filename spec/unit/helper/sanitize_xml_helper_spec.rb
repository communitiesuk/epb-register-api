describe Helper::SanitizeXmlHelper do
  let(:helper) { described_class.new }
  let(:xml) { File.read File.join Dir.pwd, "spec/fixtures/samples/DECAR-S-8.0.0/dec.xml" }
  let(:xml_with_two_unwanted_tags) { File.read File.join Dir.pwd, "spec/fixtures/samples/DECAR-S-8.0.0/dec+ar.xml" }

  context "when sanitizing xml" do
    it "removes the unwanted tags" do
      response = helper.sanitize(xml)

      expect(response).not_to include("Formatted-Report")
      expect(response).not_to include("PDF")
    end
  end

  context "when sanitizing xml where the tag appears twice" do
    it "removes both instances" do
      response = helper.sanitize(xml_with_two_unwanted_tags)

      expect(response).not_to include("Formatted-Report")
      expect(response).not_to include("PDF")
    end

    it "does not remove the content between the two tags" do
      response = helper.sanitize(xml_with_two_unwanted_tags)

      expect(response).to include("<Report>").at_least(2).times
    end
  end
end
