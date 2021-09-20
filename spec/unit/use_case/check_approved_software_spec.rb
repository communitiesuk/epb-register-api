describe UseCase::CheckApprovedSoftware do
  subject(:use_case) { described_class.new }

  context "when a domestic assessment XML is provided" do
    let(:domestic_xml) do
      xml_doc = Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0"
      xml_doc.remove_namespaces!

      xml_doc
    end

    context "and there is a domestic software list available" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("DOMESTIC_APPROVED_SOFTWARE").and_return(File.read("#{__dir__}/fixtures/domestic_software_list.json"))
      end

      context "and the software in the XML is approved" do
        before do
          domestic_xml.at("Calculation-Software-Name").children = "Lodg-o"
          domestic_xml.at("Calculation-Software-Version").children = "6.5"
        end

        it "returns true" do
          expect(use_case.execute(assessment_xml: domestic_xml, schema_name: "RdSAP")).to be true
        end
      end

      context "and the software in the XML has an approved name but not an approved version" do
        before do
          domestic_xml.at("Calculation-Software-Name").children = "Lodg-o"
          domestic_xml.at("Calculation-Software-Version").children = "5.1"
        end

        it "returns false" do
          expect(use_case.execute(assessment_xml: domestic_xml, schema_name: "RdSAP")).to be false
        end
      end

      context "and the software in the XML is not approved" do
        before do
          domestic_xml.at("Calculation-Software-Name").children = "Cheap-o"
          domestic_xml.at("Calculation-Software-Version").children = "0.0.1alpha"
        end

        it "returns false" do
          expect(use_case.execute(assessment_xml: domestic_xml, schema_name: "RdSAP")).to be false
        end
      end
    end

    context "and there is no domestic software list available" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("DOMESTIC_APPROVED_SOFTWARE").and_return nil
      end

      it "returns true" do
        expect(use_case.execute(assessment_xml: domestic_xml, schema_name: "RdSAP")).to be true
      end
    end
  end

  context "when a non-domestic assessment XML is provided" do
    let(:non_domestic_xml) do
      xml_doc = Nokogiri.XML Samples.xml "CEPC-8.0.0", "cepc"
      xml_doc.remove_namespaces!

      xml_doc
    end

    context "and there is a non-domestic software list available" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("NON_DOMESTIC_APPROVED_SOFTWARE").and_return(File.read("#{__dir__}/fixtures/non_domestic_software_list.json"))
      end

      context "and the software in the XML is approved" do
        before do
          non_domestic_xml.at("Calculation-Tool").children = "Sentinel, v4.6h"
        end

        it "returns true" do
          expect(use_case.execute(assessment_xml: non_domestic_xml, schema_name: "CEPC")).to be true
        end
      end

      context "and the software in the XML is not approved" do
        before do
          non_domestic_xml.at("Calculation-Tool").children = "Ourobouros, v2.0"
        end

        it "returns false" do
          expect(use_case.execute(assessment_xml: non_domestic_xml, schema_name: "CEPC")).to be false
        end
      end
    end

    context "and there is no non-domestic software list available" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("NON_DOMESTIC_APPROVED_SOFTWARE").and_return nil
      end

      it "returns true" do
        expect(use_case.execute(assessment_xml: non_domestic_xml, schema_name: "CEPC")).to be true
      end
    end
  end
end
