describe ViewModel::Cepc::CepcWrapper do
  context "when constructed with a valid CEPC 8.0.0 document" do
    let(:cepc) do
      xml_file = File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"
      xml_doc = Nokogiri.XML xml_file
      described_class.new(xml_doc.to_xml, "CEPC-8.0.0")
    end

    it "Returns the assessment ID" do
      expect(cepc.to_hash[:assessment_id]).to eq("0000-0000-0000-0000-0000")
    end

    it "Returns the expiry date" do
      expect(cepc.to_hash[:date_of_expiry]).to eq("2026-05-04")
    end

    it "Returns the address" do
      expect(cepc.to_hash[:address]).to eq(
        {
          address_line1: "2 Lonely Street",
          address_line2: nil,
          address_line3: nil,
          address_line4: nil,
          town: "Post-Town1",
          postcode: "A0 0AA",
        },
      )
    end
  end
end
