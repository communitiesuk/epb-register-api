describe "backfill data warehouse" do
  let(:rake) { get_task("data_export:backfill_data_warehouse") }

  context "when calling the rake" do
    let(:use_case) { instance_double(UseCase::BackfillDataWarehouse) }

    before do
      allow(ApiFactory).to receive(:backfill_data_warehouse_use_case).and_return(use_case)
      allow(use_case).to receive(:execute).and_return []
    end

    it "calls without error" do
      expect { rake.invoke("2020-05-04", "2020-06-04", "RdSAP") }.not_to raise_error
    end

    it "the use case executes when type_of_assessment is nil" do
      rake.invoke("2020-05-04", "2020-06-04")
      expect(use_case).to have_received(:execute).with({ end_date: "2020-06-04", start_date: "2020-05-04", type_of_assessment: nil }).exactly(1).times
    end

    it "raises an error when arguments are missing" do
      expect { rake.invoke }.to raise_error(Boundary::ArgumentMissing)
    end

    context "with environmental variables" do
      before do
        EnvironmentStub.with("start_date", "2020-05-04")
        EnvironmentStub.with("type_of_assessment", "RdSAP")
        EnvironmentStub.with("end_date", "2020-05-08")
      end

      after do
        EnvironmentStub.remove(%w[end_date start_date type_of_assessment])
      end

      it "calls without error" do
        expect { rake.invoke }.not_to raise_error
      end

      it "raises an error when there is no start date" do
        EnvironmentStub.remove(%w[start_date])
        expect { rake.invoke }.to raise_error(Boundary::ArgumentMissing)
      end
    end
  end
end
