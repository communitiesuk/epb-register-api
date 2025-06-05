describe Domain::AssessmentsToLink do
  subject(:domain) do
    described_class.new(data:)
  end

  context "when there is data" do
    let(:data) do
      [
        { "assessment_id" => "0000-0000-0000-0000-0012", "address_id" => "RRN-0000-0000-0000-0000-0012", "date_registered" => Time.utc(2020, 0o5, 20), "source" => "lodgement" },
        { "assessment_id" => "0000-0000-0000-0000-0000", "address_id" => "UPRN-000000000001", "date_registered" => Time.utc(2020, 0o5, 0o5), "source" => "lodgement" },
        { "assessment_id" => "0000-0000-0000-0000-0001", "address_id" => "UPRN-000000000001", "date_registered" => Time.utc(2020, 0o5, 0o5), "source" => "lodgement" },
        { "assessment_id" => "0000-0000-0000-0000-0002", "address_id" => "RRN-0000-0000-0000-0000-0002", "date_registered" => Time.utc(2020, 0o5, 0o4), "source" => "lodgement" },
        { "assessment_id" => "0000-0000-0000-0000-0007", "address_id" => "RRN-0000-0000-0000-0000-0002", "date_registered" => Time.utc(2020, 0o5, 0o4), "source" => "lodgement" },
      ]
    end

    describe "#sort_by_date" do
      it "orders the data by date registered" do
        expect(domain.sort_by_date.last["assessment_id"]).to eq "0000-0000-0000-0000-0012"
      end
    end

    describe "#set_best_address_id" do
      let(:address_base_gateway) { instance_double Gateway::AddressBaseSearchGateway }

      before do
        allow(address_base_gateway).to receive(:check_uprn_exists)
      end

      context "when an address_id that has been set manually by the team in the past is in the list" do
        let(:data) do
          [
            { "assessment_id" => "0000-0000-0000-0000-0012", "address_id" => "RRN-0000-0000-0000-0000-0012", "date_registered" => Time.utc(2020, 0o5, 20), "source" => "lodgement" },
            { "assessment_id" => "0000-0000-0000-0000-0000", "address_id" => "UPRN-000000000001", "date_registered" => Time.utc(2020, 0o5, 0o5), "source" => "lodgement" },
            { "assessment_id" => "0000-0000-0000-0000-0001", "address_id" => "UPRN-000000000001", "date_registered" => Time.utc(2020, 0o5, 0o5), "source" => "lodgement" },
            { "assessment_id" => "0000-0000-0000-0000-0002", "address_id" => "RRN-0000-0000-0000-0000-0002", "date_registered" => Time.utc(2020, 0o5, 0o4), "source" => "epb_team_update" },
            { "assessment_id" => "0000-0000-0000-0000-0007", "address_id" => "RRN-0000-0000-0000-0000-0002", "date_registered" => Time.utc(2020, 0o5, 0o4), "source" => "lodgement" },
          ]
        end

        before do
          domain.set_best_address_id(address_base_gateway:)
        end

        it "passes the manually set address id to the gateway" do
          expect(domain.best_address_id).to eq "RRN-0000-0000-0000-0000-0002"
        end
      end

      context "when there is no manually set address id in the list" do
        context "when a valid UPRN is in the list of address_ids" do
          before do
            allow(address_base_gateway).to receive(:check_uprn_exists).and_return true
          end

          it "passes the correct UPRN to the gateway" do
            domain.set_best_address_id(address_base_gateway:)
            expect(address_base_gateway).to have_received(:check_uprn_exists).with("000000000001").exactly(1).times
            expect(domain.best_address_id).to eq "UPRN-000000000001"
          end
        end

        context "when there is an invalid UPRN" do
          before do
            allow(address_base_gateway).to receive(:check_uprn_exists).and_return false
            domain.set_best_address_id(address_base_gateway:)
          end

          it "the will select the RRN associated with the oldest assessment as the address_id" do
            expect(domain.best_address_id).to eq("RRN-0000-0000-0000-0000-0002")
          end
        end

        context "when there are no UPRN's to select from" do
          let(:data) do
            [
              { "assessment_id" => "0000-0000-0000-0000-0012", "address_id" => "RRN-0000-0000-0000-0000-0012", "date_registered" => Time.utc(2020, 0o5, 20) },
              { "assessment_id" => "0000-0000-0000-0000-0002", "address_id" => "RRN-0000-0000-0000-0000-0002", "date_registered" => Time.utc(2020, 0o5, 0o4) },
              { "assessment_id" => "0000-0000-0000-0000-0007", "address_id" => "RRN-0000-0000-0000-0000-0002", "date_registered" => Time.utc(2020, 0o5, 0o4) },
            ]
          end

          before do
            domain.set_best_address_id(address_base_gateway:)
          end

          it "the will select the RRN associated with the oldest assessment as the address_id" do
            expect(domain.best_address_id).to eq("RRN-0000-0000-0000-0000-0002")
          end
        end

        context "when no data is returned" do
          let(:data) do
            []
          end

          it "raises an error" do
            expect { domain.set_best_address_id(address_base_gateway:) }.to raise_error NoMethodError
          end
        end
      end
    end

    describe "#get_assessment_ids" do
      it "returns the assessment ids from the data" do
        expected_array = %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001 0000-0000-0000-0000-0002 0000-0000-0000-0000-0007 0000-0000-0000-0000-0012]
        expect((domain.get_assessment_ids - expected_array) | (expected_array - domain.get_assessment_ids)).to be_empty
      end
    end
  end

  context "when there is no data" do
    let(:data) do
      []
    end

    it "returns true" do
      expect(domain.data.empty?).to be true
    end
  end
end
