require "rspec"

describe "BackfillMatchedAddress" do
  include RSpecRegisterApiServiceMixin

  let(:addressing_gateway) do
    instance_double(Gateway::AddressingApiGateway)
  end

  let(:assessment_address_ids) do
    ActiveRecord::Base.connection.exec_query(
      "SELECT assessment_id, matched_address_id, matched_confidence FROM assessments_address_id",
    )
  end

  before do
    scheme_id = add_scheme_and_get_id
    add_super_assessor(scheme_id:)

    sap_schema = "SAP-Schema-19.1.0".freeze
    sap_xml = Nokogiri.XML Samples.xml(sap_schema, "epc")
    call_lodge_assessment(scheme_id:, schema_name: sap_schema, xml_document: sap_xml, ensure_uprns: false)

    allow(Gateway::AddressingApiGateway).to receive(:new).and_return(addressing_gateway)
  end

  after do
    puts "Truncating tables"
    ActiveRecord::Base.connection.exec_query(
      "TRUNCATE TABLE assessments CASCADE",
    )
  end

  context "when the task run with a single match per address" do
    before do
      allow($stdout).to receive(:puts)
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199990129", "address" => "1 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "99.3" },
        ],
        [
          { "uprn" => "199990130", "address" => "1 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "98.3" },
        ],
      )
    end

    it "reports one address has been matched" do
      expect { get_task("oneoff:address_match_assessments").invoke }.to output(
        /matched:1/,
      ).to_stdout
    end

    it "calls the AddressingAPIGateway service with the right arguments" do
      get_task("oneoff:address_match_assessments").invoke
      expect(addressing_gateway).to have_received(:match_address).once
          .with(
            address_line_1: "1 Some Street",
            address_line_2: "Some Area",
            address_line_3: "Some County",
            address_line_4: nil,
            town: "Whitbury",
            postcode: "SW1A 2AA",
          )
    end

    it "calls the AddressingAPIGateway multiple times if task called multiple times" do
      get_task("oneoff:address_match_assessments").invoke
      get_task("oneoff:address_match_assessments").invoke
      expect(addressing_gateway).to have_received(:match_address).twice
    end

    it "updates the assessment_address_id_row" do
      get_task("oneoff:address_match_assessments").invoke
      row = assessment_address_ids.find { |r| r["assessment_id"] == "0000-0000-0000-0000-0000" }
      expect(row["matched_address_id"]).to eq("199990129")
      expect(row["matched_confidence"]).to eq(99.3)
    end

    it "updates the assessment_address_id row with the second run match" do
      get_task("oneoff:address_match_assessments").invoke
      get_task("oneoff:address_match_assessments").invoke
      row = assessment_address_ids.find { |r| r["assessment_id"] == "0000-0000-0000-0000-0000" }
      expect(row["matched_address_id"]).to eq("199990130")
      expect(row["matched_confidence"]).to eq(98.3)
    end
  end

  context "when there are multiple matches but one has more confidence" do
    before do
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199990129", "address" => "11 Some Street, Some Area, Some County, Whitbury, SW1A 2AA", "confidence" => "9.0" },
          { "uprn" => "199990144", "address" => "12 Some Street, Some Area, Some County, Whitbury, SW1A 2AA", "confidence" => "90.9" },

        ],
      )
      allow($stdout).to receive(:puts)
    end

    it "reports one address has been matched" do
      expect { get_task("oneoff:address_match_assessments").invoke }.to output(
        /unmatched:0 matched:1/,
      ).to_stdout
    end

    it "updates the assessment_address_id_row" do
      get_task("oneoff:address_match_assessments").invoke
      row = assessment_address_ids.find { |r| r["assessment_id"] == "0000-0000-0000-0000-0000" }
      expect(row["matched_address_id"]).to eq("199990144")
      expect(row["matched_confidence"]).to eq(90.9)
    end
  end

  context "when the matches have multiple results with same confidence" do
    before do
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199990129", "address" => "1A Some Street, Some Area, Some County, Whitbury, SW1A 2AA", "confidence" => "46.2" },
          { "uprn" => "199990144", "address" => "1B Some Street, Some Area, Some County, Whitbury, SW1A 2AA", "confidence" => "46.2" },
        ],
      )
      allow($stdout).to receive(:puts)
    end

    it "reports one address has not been matched" do
      expect { get_task("oneoff:address_match_assessments").invoke }.to output(
        /unmatched:1 matched:0/,
      ).to_stdout
    end

    it "updates the assessment_address_id_row" do
      get_task("oneoff:address_match_assessments").invoke
      row = assessment_address_ids.find { |r| r["assessment_id"] == "0000-0000-0000-0000-0000" }
      expect(row["matched_address_id"]).to eq("unknown")
      expect(row["matched_confidence"]).to eq(46.2)
    end
  end

  context "when there are no matches for the address" do
    before do
      allow(addressing_gateway).to receive(:match_address).and_return([])
      allow($stdout).to receive(:puts)
    end

    it "reports one address has not been matched" do
      expect { get_task("oneoff:address_match_assessments").invoke }.to output(
        /unmatched:1 matched:0/,
      ).to_stdout
    end

    it "updates the assessment_address_id_row" do
      get_task("oneoff:address_match_assessments").invoke
      row = assessment_address_ids.find { |r| r["assessment_id"] == "0000-0000-0000-0000-0000" }
      expect(row["matched_address_id"]).to eq("none")
      expect(row["matched_confidence"]).to be_nil
    end
  end

  context "when calling the task twice for assessments skipping ones with a matched address" do
    before do
      allow($stdout).to receive(:puts)
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199990129", "address" => "1 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "99.3" },
        ],
      )
      get_task("oneoff:address_match_assessments").invoke
    end

    before(:all) do
      EnvironmentStub.with("SKIP_EXISTING", "true")
    end

    after(:all) do
      EnvironmentStub.remove(%w[SKIP_EXISTING])
    end

    it "reports no assessments have been processed" do
      expect { get_task("oneoff:address_match_assessments").invoke }.to output(
        /unmatched:0 matched:0/,
      ).to_stdout
    end

    it "reports it is skipping assessments with existing matches" do
      expect { get_task("oneoff:address_match_assessments").invoke }.to output(
        /skipping assessments with an existing match/,
      ).to_stdout
    end

    it "called the addressing gateway once" do
      expect(addressing_gateway).to have_received(:match_address).once
    end
  end

  context "when calling the task with a date range" do
    before do
      allow($stdout).to receive(:puts)
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199990129", "address" => "1 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "99.3" },
        ],
      )
    end

    after(:all) do
      EnvironmentStub.remove(%w[SKIP_EXISTING DATE_FROM DATE_END])
    end

    it "does not process any assessments outside of the range" do
      EnvironmentStub.with("DATE_FROM", "2023-05-01")
      EnvironmentStub.with("DATE_TO", "2024-05-01")

      expect { get_task("oneoff:address_match_assessments").invoke }.to output(
        /unmatched:0 matched:0/,
      ).to_stdout
    end

    it "processes the assesment inside the range" do
      EnvironmentStub.with("DATE_FROM", "2022-05-01")
      EnvironmentStub.with("DATE_TO", "2023-05-01")

      expect { get_task("oneoff:address_match_assessments").invoke }.to output(
        /unmatched:0 matched:1/,
      ).to_stdout
    end

    it "does not process any in the range if skip_existing is true, on the second run" do
      EnvironmentStub.with("DATE_FROM", "2022-05-01")
      EnvironmentStub.with("DATE_TO", "2023-05-01")
      EnvironmentStub.with("SKIP_EXISTING", "true")
      get_task("oneoff:address_match_assessments").invoke

      expect { get_task("oneoff:address_match_assessments").invoke }.to output(
        /unmatched:0 matched:0/,
      ).to_stdout
    end
  end
end
