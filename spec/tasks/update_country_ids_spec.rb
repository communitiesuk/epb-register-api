describe "update country ids on assessments" do
  let(:rake) { get_task("maintenance:update_country_ids") }
  let(:use_case) { instance_double(UseCase::UpdateCountryId) }

  context "when invoking a rake without arguments" do
    it "raises an missing argument error" do
      expect { rake.invoke }.to raise_error(Boundary::ArgumentMissing)
    end
  end

  context "when invoking a rake with the correct ENV variable" do
    before do
      EnvironmentStub.with("ASSESSMENTS_IDS", "0000-0000-0000-0000-0000, 0000-0000-0000-0000-0001, 0000-0000-0000-0000-0002")
      allow(ApiFactory).to receive(:update_country_id_use_case).and_return(use_case)
      allow(use_case).to receive(:execute)
    end

    after do
      EnvironmentStub.remove(%w[ASSESSMENTS_IDS])
    end

    it "does not raise an error" do
      expect { rake.invoke }.not_to raise_error
    end

    it "executes the use case with the correct args" do
      rake.invoke
      expect(use_case).to have_received(:execute).with(assessments_ids: "0000-0000-0000-0000-0000, 0000-0000-0000-0000-0001, 0000-0000-0000-0000-0002").exactly(1).times
    end
  end
end
