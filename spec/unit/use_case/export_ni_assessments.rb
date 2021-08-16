describe UseCase::ExportNiAssessments do
  context "when exporting data for attribute storage call the use case" do
    subject do
      described_class.new(ni_export_gateway: ni_gateway, xml_gateway:xml_gateway )
    end

    let(:ni_gateway) {
      instance_double(Gateway::ExportNiGateway)
    }

    let(:xml_gateway) {
      instance_double(Gateway::AssessmentsXmlGateway)
    }

      before do
        allow(ni_gateway).to receive(:fetch_assessments).with(%w[RdSAP SAP]).and_return([{ "assessment_id" => "0000-0000-0000-0000-0000" },
                                                                     { "assessment_id" => "8888-0000-0000-0000-0002" }, { "assessment_id" => "9999-0000-0000-0000-0000" }])
        allow(xml_gateway).to receive(:fetch).and_return("")
        subject.execute(%w[RdSAP SAP])
      end


      it 'loops over the lodged assessments and extract the correct certificate' do
        expect(xml_gateway).to have_received(:fetch).exactly(3).times
      end

  end
end
