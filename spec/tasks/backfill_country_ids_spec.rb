describe "backfill assessments with country ids" do
  let(:rake) { get_task("maintenance:backfill_country_ids") }
  let(:use_case) { instance_double(UseCase::BackfillCountryId) }

  context "when invoking a rake without arguments" do
    it "raises an missing argument error" do
      expect { rake.invoke }.to raise_error(Boundary::ArgumentMissing)
    end
  end

  context "when invoking a rake with the correct ENV variables" do
    before do
      EnvironmentStub.with("DATE_FROM", "2023-05-01")
      EnvironmentStub.with("DATE_TO", "2024-05-01")
      EnvironmentStub.with("ASSESSMENT_TYPES", "RdSAP,SAP")
      allow(ApiFactory).to receive(:backfill_country_id_use_case).and_return(use_case)
      allow(use_case).to receive(:execute)
      rake.invoke
    end

    after do
      EnvironmentStub.remove(%w[DATE_FROM DATE_TO ASSESSMENT_TYPES])
    end

    it "executes the use case with the correct args" do
      expect(use_case).to have_received(:execute).with(date_from: "2023-05-01", date_to: "2024-05-01", assessment_types: %w[RdSAP SAP]).exactly(1).times
    end
  end

  context "when invoking a rake without the assessment_types" do
    before do
      EnvironmentStub.with("DATE_FROM", "2023-05-01")
      EnvironmentStub.with("DATE_TO", "2024-05-01")

      allow(ApiFactory).to receive(:backfill_country_id_use_case).and_return(use_case)
      allow(use_case).to receive(:execute)
      rake.invoke
    end

    after do
      EnvironmentStub.remove(%w[DATE_FROM DATE_TO])
    end

    it "executes the use case with the correct args" do
      expect(use_case).to have_received(:execute).with(date_from: "2023-05-01", date_to: "2024-05-01", assessment_types: nil).exactly(1).times
    end
  end

  context "when there is no data" do
    before do
      EnvironmentStub.with("DATE_FROM", "2023-05-01")
      EnvironmentStub.with("DATE_TO", "2024-05-01")

      allow(ApiFactory).to receive(:backfill_country_id_use_case).and_return(use_case)
      allow(use_case).to receive(:execute).and_raise Boundary::NoAssessments, " dates "
    end

    after do
      EnvironmentStub.remove(%w[DATE_FROM DATE_TO])
    end

    it "prints the error to the standard output" do
      expect { rake.invoke }.to output(/no assessments found for/).to_stdout
    end
  end
end
