require "rspec"

describe "BackfillMatchedAddress" do
  include RSpecRegisterApiServiceMixin

  let(:addressing_gateway) do
    instance_double(Gateway::AddressingApiGateway)
  end
  let(:assessments_address_id_gateway) do
    instance_double(Gateway::AssessmentsAddressIdGateway)
  end
  let(:data_warehouse_queues_gateway) do
    instance_double(Gateway::DataWarehouseQueuesGateway)
  end

  around do |test|
    original_stage = ENV["STAGE"]
    Events::Broadcaster.enable!
    ENV["STAGE"] = "mock"
    test.run
    Events::Broadcaster.disable!
    ENV["STAGE"] = original_stage
  end

  before do
    EnvironmentStub.remove(%w[DATE_TO DATE_FROM])
    allow($stdout).to receive(:puts)
    Events::Broadcaster.accept_only! :matched_address
    allow(Gateway::AddressingApiGateway).to receive(:new).and_return(addressing_gateway)
    allow(Gateway::AssessmentsAddressIdGateway).to receive(:new).and_return(assessments_address_id_gateway)
    allow(Gateway::DataWarehouseQueuesGateway).to receive(:new).and_return(data_warehouse_queues_gateway)
    allow(Helper::AddressMatchAssessment).to receive(:find_unmatched_assessments)
    allow(assessments_address_id_gateway).to receive(:update_matched_batch)
    allow(data_warehouse_queues_gateway).to receive(:push_to_queue)
  end

  after do
    Events::Broadcaster.accept_any!
    EnvironmentStub.remove(%w[DATE_TO DATE_FROM])
  end

  context "when the task runs with a single match for a scottish address" do
    before do
      allow(Helper::AddressMatchAssessment).to receive(:find_unmatched_assessments).and_return([{ "assessment_id" => "0000-0000-0000-0000-0000", "address_line1" => "1 LOVELY ROAD", "address_line2" => "NICE ESTATE", "address_line3" => "", "address_line4" => nil, "postcode" => "EH1 2NG", "town" => "TOWN" }])
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "299990129", "address" => "1 SOME STREET, SOME AREA, SOME COUNTY, EDINBURGH, EH1 2BE", "confidence" => "98.3" },
        ],
      )
      EnvironmentStub.with("IS_SCOTTISH", "true")
    end

    after(:all) do
      EnvironmentStub.remove(%w[IS_SCOTTISH])
    end

    it "updates the matched address_id in the right database schema" do
      get_task("oneoff:address_match_assessments").invoke
      expect(assessments_address_id_gateway).to have_received(:update_matched_batch).with(["('0000-0000-0000-0000-0000', '299990129', 98.3)"], "true").exactly(1).times
    end

    it "does not push a message to redis" do
      get_task("oneoff:address_match_assessments").invoke
      expect(data_warehouse_queues_gateway).not_to have_received(:push_to_queue)
    end
  end

  context "when the addressing api endpoint returns errors for a single assessment (scottish epc)" do
    before(:all) do
      EnvironmentStub.with("IS_SCOTTISH", "true")
    end

    before do
      allow(Helper::AddressMatchAssessment).to receive(:find_unmatched_assessments).and_return([{ "assessment_id" => "0000-0000-0000-0000-0000", "address_line1" => "1 LOVELY ROAD", "address_line2" => "NICE ESTATE", "address_line3" => "", "address_line4" => nil, "postcode" => "EH1 2NG", "town" => "TOWN" }])
    end

    after(:all) do
      EnvironmentStub.remove(%w[IS_SCOTTISH])
    end

    context "when the error occurs only once" do
      before do
        call_count = 0

        allow(addressing_gateway).to receive(:match_address) do
          call_count += 1
          raise Errors::ApiResponseError if call_count == 1

          [
            { "uprn" => "299990129", "address" => "1 LOVELY ROAD, NICE ESTATE, TOWN, EH1 2NG", "confidence" => "98.3" },
          ]
        end
      end

      it "calls the addressing api with expected parameters twice" do
        get_task("oneoff:address_match_assessments").invoke
        expect(addressing_gateway).to have_received(:match_address).twice
                                                                   .with(
                                                                     address_line_1: "1 LOVELY ROAD",
                                                                     address_line_2: "NICE ESTATE",
                                                                     address_line_3: "",
                                                                     address_line_4: "",
                                                                     postcode: "EH1 2NG",
                                                                     town: "TOWN",
                                                                   )
      end
    end

    context "when the error persists for the same assessment" do
      before do
        allow(Sentry).to receive(:capture_exception)
        allow(addressing_gateway).to receive(:match_address).and_raise(Errors::ApiResponseError, "Connection refused")
      end

      it "calls the addressing api with the expected parameters three times" do
        get_task("oneoff:address_match_assessments").invoke
        expect(addressing_gateway).to have_received(:match_address).exactly(3).times
                                                                   .with(
                                                                     address_line_1: "1 LOVELY ROAD",
                                                                     address_line_2: "NICE ESTATE",
                                                                     address_line_3: "",
                                                                     address_line_4: "",
                                                                     postcode: "EH1 2NG",
                                                                     town: "TOWN",
                                                                   )
      end

      it "sends the error to sentry" do
        get_task("oneoff:address_match_assessments").invoke
        expect(Sentry).to have_received(:capture_exception).with(
          have_attributes(
            class: Errors::BackfillAddressMatchError,
            message: "Address matching backfill failed for assessment 0000-0000-0000-0000-0000: Errors::ApiResponseError - Connection refused",
          ),
        ).exactly(1).times
      end
    end
  end

  context "when the task runs with missing mandatory addressing api parameters" do
    before do
      allow(Helper::AddressMatchAssessment).to receive(:find_unmatched_assessments).and_return([{ "assessment_id" => "0000-0000-0000-0000-0003", "address_line1" => nil, "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" }])
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199990129", "address" => "1 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "99.3" },
        ],
      )
    end

    it "calls the addressing api with all parameters" do
      get_task("oneoff:address_match_assessments").invoke
      expect(addressing_gateway).to have_received(:match_address).once
                                                                 .with(
                                                                   address_line_1: "",
                                                                   address_line_2: "",
                                                                   address_line_3: "",
                                                                   address_line_4: "",
                                                                   town: "Whitbury",
                                                                   postcode: "SW1A 2AA",
                                                                 )
    end
  end

  context "when the task runs" do
    before do
      allow(Helper::AddressMatchAssessment).to receive(:find_unmatched_assessments).and_return([{ "assessment_id" => "0000-0000-0000-0000-0000", "address_line1" => "1 Some Street", "address_line2" => "Some Area", "address_line3" => "Some County", "address_line4" => nil, "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                                                                                                { "assessment_id" => "0000-0000-0000-0000-0001", "address_line1" => "1 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                                                                                                { "assessment_id" => "0000-0000-0000-0000-0002", "address_line1" => "1 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                                                                                                { "assessment_id" => "0000-0000-0000-0000-0003", "address_line1" => "1 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" }])
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199990129", "address" => "1 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "99.3" },
        ],
      )
    end

    it "calls the AddressingAPIGateway service with the right arguments" do
      get_task("oneoff:address_match_assessments").invoke
      expect(addressing_gateway).to have_received(:match_address).once
          .with(
            address_line_1: "1 Some Street",
            address_line_2: "Some Area",
            address_line_3: "Some County",
            address_line_4: "",
            town: "Whitbury",
            postcode: "SW1A 2AA",
          )
      expect(addressing_gateway).to have_received(:match_address).thrice
                                                                 .with(
                                                                   address_line_1: "1 Some Street",
                                                                   address_line_2: "",
                                                                   address_line_3: "",
                                                                   address_line_4: "",
                                                                   town: "Whitbury",
                                                                   postcode: "SW1A 2AA",
                                                                 )
    end
  end

  context "when the task runs with matched results" do
    before do
      allow(Helper::AddressMatchAssessment).to receive(:find_unmatched_assessments).and_return([{ "assessment_id" => "0000-0000-0000-0000-0000", "address_line1" => "1 Some Street", "address_line2" => "Some Area", "address_line3" => "Some County", "address_line4" => nil, "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                                                                                                { "assessment_id" => "0000-0000-0000-0000-0001", "address_line1" => "2 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                                                                                                { "assessment_id" => "0000-0000-0000-0000-0002", "address_line1" => "3 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                                                                                                { "assessment_id" => "0000-0000-0000-0000-0003", "address_line1" => "4 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" }])
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199990129", "address" => "1 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "99.3" },
        ],
        [
          { "uprn" => "199990130", "address" => "2 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "98.3" },
        ],
        [
          { "uprn" => "199990131", "address" => "3 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "97.3" },
        ],
        [
          { "uprn" => "199990132", "address" => "4 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "97.3" },
        ],
      )
      get_task("oneoff:address_match_assessments").invoke
    end

    it "saves the assessments with a match" do
      expected_args = ["('0000-0000-0000-0000-0000', '199990129', 99.3)", "('0000-0000-0000-0000-0001', '199990130', 98.3)", "('0000-0000-0000-0000-0002', '199990131', 97.3)", "('0000-0000-0000-0000-0003', '199990132', 97.3)"], false
      expect(assessments_address_id_gateway).to have_received(:update_matched_batch).with(*expected_args).exactly(1).times
    end
  end

  context "when there are multiple matches but one has more confidence" do
    before do
      allow(Helper::AddressMatchAssessment).to receive(:find_unmatched_assessments).and_return([{ "assessment_id" => "0000-0000-0000-0000-0010", "address_line1" => "1a Some Street", "address_line2" => "Some Area", "address_line3" => "Some County", "address_line4" => nil, "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                                                                                                { "assessment_id" => "0000-0000-0000-0000-0011", "address_line1" => "2a Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" }])
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199990140", "address" => "1A SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "99.3" },
          { "uprn" => "199990129", "address" => "1 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "0.3" },
        ],
        [
          { "uprn" => "199990141", "address" => "2A SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "98.3" },
          { "uprn" => "199990130", "address" => "2 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "0.3" },
        ],
      )
      allow($stdout).to receive(:puts)
    end

    it "updates the assessment_address_id_row" do
      expected_args = ["('0000-0000-0000-0000-0010', '199990140', 99.3)",
                       "('0000-0000-0000-0000-0011', '199990141', 98.3)"],
                      false
      get_task("oneoff:address_match_assessments").invoke
      expect(assessments_address_id_gateway).to have_received(:update_matched_batch).with(*expected_args).exactly(1).times
    end
  end

  context "when the matches have multiple results with same confidence" do
    before do
      allow(Helper::AddressMatchAssessment).to receive(:find_unmatched_assessments).and_return([{ "assessment_id" => "0000-0000-0000-0000-0000", "address_line1" => "1 Some Street", "address_line2" => "Some Area", "address_line3" => "Some County", "address_line4" => nil, "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                                                                                                { "assessment_id" => "0000-0000-0000-0000-0001", "address_line1" => "2 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" }])
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199990143", "address" => "1A Some Street, Some Area, Some County, Whitbury, SW1A 2AA", "confidence" => "46.2" },
          { "uprn" => "199990144", "address" => "1B Some Street, Some Area, Some County, Whitbury, SW1A 2AA", "confidence" => "46.2" },
        ],
        [
          { "uprn" => "199990143", "address" => "2A Some Street, Some Area, Some County, Whitbury, SW1A 2AA", "confidence" => "47.2" },
          { "uprn" => "199990144", "address" => "2B Some Street, Some Area, Some County, Whitbury, SW1A 2AA", "confidence" => "47.2" },
        ],
      )
      allow($stdout).to receive(:puts)
    end

    it "updates the assessment_address_id_row" do
      expected_args = ["('0000-0000-0000-0000-0000', 'unknown', 46.2)", "('0000-0000-0000-0000-0001', 'unknown', 47.2)"], false
      get_task("oneoff:address_match_assessments").invoke
      expect(assessments_address_id_gateway).to have_received(:update_matched_batch).with(*expected_args)
    end

    it "does not push message to redis" do
      get_task("oneoff:address_match_assessments").invoke
      expect(data_warehouse_queues_gateway).not_to have_received(:push_to_queue)
    end
  end

  context "when there are no matches for the address" do
    before do
      allow(Helper::AddressMatchAssessment).to receive(:find_unmatched_assessments).and_return([{ "assessment_id" => "0000-0000-0000-0000-0100", "address_line1" => "100 Some Street", "address_line2" => "Some Area", "address_line3" => "Some County", "address_line4" => nil, "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                                                                                                { "assessment_id" => "0000-0000-0000-0000-0101", "address_line1" => "101 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" }])
      allow(addressing_gateway).to receive(:match_address).and_return(
        [],
        [],
      )
      allow($stdout).to receive(:puts)
    end

    it "updates the assessment_address_id_row" do
      get_task("oneoff:address_match_assessments").invoke
      expect(assessments_address_id_gateway).not_to have_received(:update_matched_batch)
    end

    it "does not push message to redis" do
      get_task("oneoff:address_match_assessments").invoke
      expect(data_warehouse_queues_gateway).not_to have_received(:push_to_queue)
    end
  end

  context "when calling the task to skip assessments with a matched address" do
    before do
      allow($stdout).to receive(:puts)
      allow(Helper::AddressMatchAssessment).to receive(:find_unmatched_assessments).and_return([{ "assessment_id" => "0000-0000-0000-0000-1000", "address_line1" => "111 Some Street", "address_line2" => "Some Area", "address_line3" => "Some County", "address_line4" => nil, "postcode" => "SW1A 2AA", "town" => "Whitbury" }])
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199991111", "address" => "111 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "99.3" },
        ],
      )
    end

    before(:all) do
      EnvironmentStub.with("SKIP_EXISTING", "true")
    end

    after(:all) do
      EnvironmentStub.remove(%w[SKIP_EXISTING])
    end

    it "passes the parameter on to the address match assessment helper" do
      get_task("oneoff:address_match_assessments").invoke
      expect(Helper::AddressMatchAssessment).to have_received(:find_unmatched_assessments).with(is_scottish: false, date_from: nil, date_to: nil, skip_existing: true).once
    end
  end

  context "when calling the task with a date range" do
    before do
      allow($stdout).to receive(:puts)
      allow(Helper::AddressMatchAssessment).to receive(:find_unmatched_assessments).and_return([{ "assessment_id" => "0000-0000-0000-0000-1000", "address_line1" => "151 Some Street", "address_line2" => "Some Area", "address_line3" => "Some County", "address_line4" => nil, "postcode" => "SW1A 2AA", "town" => "Whitbury" }])
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199990151", "address" => "151 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "99.3" },
        ],
      )
    end

    after do
      EnvironmentStub.remove(%w[SKIP_EXISTING DATE_FROM DATE_TO])
    end

    it "raises an error if only one date is given" do
      EnvironmentStub.with("DATE_FROM", "2023-05-01")
      expect { get_task("oneoff:address_match_assessments").invoke }.to raise_error(Boundary::ArgumentMissing).with_message("A required argument is missing: DATE_TO")
    end

    it "raises an error if invalid dates are given" do
      EnvironmentStub.with("DATE_FROM", "not a date")
      EnvironmentStub.with("DATE_TO", "2024-05-01")
      expect { get_task("oneoff:address_match_assessments").invoke }.to raise_error ArgumentError
    end

    it "raises an error if the date range is not valid" do
      EnvironmentStub.with("DATE_FROM", "2025-05-01")
      EnvironmentStub.with("DATE_TO", "2023-05-01")
      expect { get_task("oneoff:address_match_assessments").invoke }.to raise_error ArgumentError
    end

    it "does not raise an error if the date range is the same day" do
      EnvironmentStub.with("DATE_FROM", "2023-05-01")
      EnvironmentStub.with("DATE_TO", "2023-05-01")
      expect { get_task("oneoff:address_match_assessments").invoke }.not_to raise_error
    end

    it "passes the dates onto the helper" do
      EnvironmentStub.with("DATE_FROM", "2023-05-01")
      EnvironmentStub.with("DATE_TO", "2024-05-01")
      get_task("oneoff:address_match_assessments").invoke
      expect(Helper::AddressMatchAssessment).to have_received(:find_unmatched_assessments).with(is_scottish: false, date_from: "2023-05-01", date_to: "2024-05-01", skip_existing: false).once
    end
  end

  context "when the number of EPCs is greater than the batch size" do
    before do
      allow(Helper::AddressMatchAssessment).to receive(:find_unmatched_assessments).and_return([{ "assessment_id" => "0000-0000-0000-0000-0000", "address_line1" => "1 Some Street", "address_line2" => "Some Area", "address_line3" => "Some County", "address_line4" => nil, "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                                                                                                { "assessment_id" => "0000-0000-0000-0000-0001", "address_line1" => "2 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                                                                                                { "assessment_id" => "0000-0000-0000-0000-0002", "address_line1" => "3 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" }])
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199990129", "address" => "1 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "99.3" },
        ],
        [
          { "uprn" => "199990130", "address" => "2 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "98.3" },
        ],
        [
          { "uprn" => "199990131", "address" => "3 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "97.3" },
        ],
      )
      EnvironmentStub.with("BATCH_SIZE", "2")
      allow(Gateway::AssessmentsAddressIdGateway).to receive(:new).and_return(assessments_address_id_gateway)
      allow(Gateway::DataWarehouseQueuesGateway).to receive(:new).and_return(data_warehouse_queues_gateway)
      allow(assessments_address_id_gateway).to receive(:update_matched_batch)
      allow(data_warehouse_queues_gateway).to receive(:push_to_queue)
      get_task("oneoff:address_match_assessments").invoke
    end

    after do
      EnvironmentStub.remove(%w[BATCH_SIZE])
    end

    it "sends the sliced data to database" do
      expect(assessments_address_id_gateway)
        .to have_received(:update_matched_batch)
              .twice

      expect(assessments_address_id_gateway).to have_received(:update_matched_batch).with(["('0000-0000-0000-0000-0000', '199990129', 99.3)", "('0000-0000-0000-0000-0001', '199990130', 98.3)"], false).exactly(1).times
      expect(assessments_address_id_gateway).to have_received(:update_matched_batch).with(["('0000-0000-0000-0000-0002', '199990131', 97.3)"], false).exactly(1).times
    end

    it "sends the sliced payload to Redis" do
      expect(data_warehouse_queues_gateway)
        .to have_received(:push_to_queue)
              .twice

      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).with(:backfill_matched_address_update, %w[0000-0000-0000-0000-0000:199990129 0000-0000-0000-0000-0001:199990130]).exactly(1).times
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).with(:backfill_matched_address_update, ["0000-0000-0000-0000-0002:199990131"]).exactly(1).times
    end
  end
end
