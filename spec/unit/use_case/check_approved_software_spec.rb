describe UseCase::CheckApprovedSoftware do
  subject(:use_case) { described_class.new(logger: logger) }

  let(:logger) { instance_spy Logger }

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

      context "when major version of the software in the XML is approved" do
        before do
          domestic_xml.at("Calculation-Software-Name").children = "Lodg-o"
        end

        version_formats = [
          "4.06",
          "4.06r0008",
          "6",
          "6.5",
          "6.05.082",
          "v94",
          "v94.0.1.5",
          "Twelve",
          "Version: 1.5.1.12",
        ]

        version_formats.each do |format|
          it "returns true for #{format} format" do
            domestic_xml.at("Calculation-Software-Version").children = format

            expect(use_case.execute(assessment_xml: domestic_xml, schema_name: "RdSAP-Schema-20.0.0")).to be true
          end
        end
      end

      context "when software in the XML has an approved name but not an approved major version" do
        before do
          domestic_xml.at("Calculation-Software-Name").children = "Lodg-o"
        end

        version_formats = [
          "4.05",
          "4.05r0008",
          "5",
          "5.5",
          "5.05.082",
          "v91",
          "v91.0.1.5",
          "Six",
          "Version: 0.5.1.12",
          "2.1.1.9",
        ]

        version_formats.each do |format|
          it "returns false for #{format} format" do
            domestic_xml.at("Calculation-Software-Version").children = format

            expect(use_case.execute(assessment_xml: domestic_xml, schema_name: "RdSAP-Schema-20.0.0")).to be false
          end
        end
      end

      context "and the software in the XML is not approved" do
        before do
          domestic_xml.at("Calculation-Software-Name").children = "Cheap-o"
          domestic_xml.at("Calculation-Software-Version").children = "0.0.1alpha"
        end

        it "returns false" do
          expect(use_case.execute(assessment_xml: domestic_xml, schema_name: "RdSAP-Schema-20.0.0")).to be false
        end
      end
    end

    context "and a domestic software list is available but has a parse error" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("DOMESTIC_APPROVED_SOFTWARE").and_return('["bad software list"]]')

        use_case.execute(assessment_xml: domestic_xml, schema_name: "RdSAP-Schema-20.0.0")
      end

      it "logs out an error" do
        expect(logger).to have_received :error
      end
    end

    context "and there is no domestic software list available" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("DOMESTIC_APPROVED_SOFTWARE").and_return nil
      end

      it "returns true" do
        expect(use_case.execute(assessment_xml: domestic_xml, schema_name: "RdSAP-Schema-20.0.0 ")).to be true
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
          expect(use_case.execute(assessment_xml: non_domestic_xml, schema_name: "CEPC-8.0.0")).to be true
        end
      end

      context "and the software in the XML is not approved" do
        before do
          non_domestic_xml.at("Calculation-Tool").children = "Ourobouros, v2.0"
        end

        it "returns false" do
          expect(use_case.execute(assessment_xml: non_domestic_xml, schema_name: "CEPC-8.0.0")).to be false
        end
      end
    end

    context "and a non-domestic software list is available but has a parse error" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("NON_DOMESTIC_APPROVED_SOFTWARE").and_return('["bad software list"]]')

        use_case.execute(assessment_xml: non_domestic_xml, schema_name: "CEPC-8.0.0")
      end

      it "logs out an error" do
        expect(logger).to have_received :error
      end
    end

    context "and there is no non-domestic software list available" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("NON_DOMESTIC_APPROVED_SOFTWARE").and_return nil
      end

      it "returns true" do
        expect(use_case.execute(assessment_xml: non_domestic_xml, schema_name: "CEPC-8.0.0")).to be true
      end
    end
  end
end
