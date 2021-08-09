describe UseCase::AssessmentMeta do
  context "Extract meta data from the database for an assessment" do

    let(:gateway){
      instance_double("AssessmentMetaGateway")
    }

    subject {UseCase::AssessmentMeta.new(gateway)}

    before do
      allow(gateway).to receive(:fetch).and_return({assessment: "0000-0000-0000-0000-0000"})
    end

    it 'executes the use case which calls the gateway' do
      expect(subject.execute("0000-0000-0000-0000-0000")).to eq({assessment: "0000-0000-0000-0000-0000"})
    end
  end
  end
