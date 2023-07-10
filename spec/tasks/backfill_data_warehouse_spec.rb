describe "backfill data warehouse" do
  let(:rake) { get_task("data_export:backfill_data_warehouse") }

  context "when calling the rake" do
    let(:use_case) { instance_double(UseCase::BackfillDataWarehouse) }

    before do
      allow(ApiFactory).to receive(:backfill_data_warehouse_use_case).and_return(use_case)
      allow(use_case).to receive(:execute).and_return []
    end

    it "calls without error" do
      expect { rake.invoke("0000-0000-0000-0000-0000", "2020-05-04", "RdSAP-Schema-20.0.0") }.not_to raise_error
    end

    it "raises an error when arguments are missing" do
      expect { rake.invoke }.to raise_error(Boundary::ArgumentMissing)
    end

    it "raises error if the rrn does not exist" do
      allow(use_case).to receive(:execute).and_raise(Boundary::NoData.new("No assessment for this rrn"))
      expect { rake.invoke("0000-0000-0000-0000-0001", "2020-05-04", "RdSAP-Schema-20.0.0") }.to raise_error(Boundary::NoData)
    end

    it "raises error if the rrn date comes before the start date" do
      allow(use_case).to receive(:execute).and_raise(Boundary::InvalidDate.new)
      expect { rake.invoke("0000-0000-0000-0000-0001", "2020-05-14", "RdSAP-Schema-20.0.0") }.to raise_error(Boundary::InvalidDate)
    end

    it "raises error if there are no assessments to export" do
      allow(use_case).to receive(:execute).and_raise(Boundary::NoData.new("No assessments to export"))
      expect { rake.invoke("0000-0000-0000-0000-0001", "2020-05-04", "SAP-Schema-19.0.0") }.to raise_error(Boundary::NoData)
    end

    context "when the dry_run environment variable is set" do
      before do
        EnvironmentStub.with("dry_run", "true")
      end

      after do
        EnvironmentStub.remove(%w[dry_run])
      end

      it "returns the number of assessments to export" do
        allow(use_case).to receive(:execute).and_return 2
        expect { rake.invoke("0000-0000-0000-0000-0000", "2020-05-04", "RdSAP-Schema-20.0.0") }.not_to raise_error
      end
    end

    context "with environmental variables" do
      before do
        EnvironmentStub.with("rrn", "0000-0000-0000-0000-0000")
        EnvironmentStub.with("start_date", "2020-05-04")
        EnvironmentStub.with("schema_type", "RdSAP-Schema-20.0.0")
      end

      after do
        EnvironmentStub.remove(%w[rrn start_date schema_type])
      end

      it "calls without error" do
        expect { rake.invoke }.not_to raise_error
      end
    end
  end
end
