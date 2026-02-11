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

  let(:scottish_assessment_address_ids) do
    ActiveRecord::Base.connection.exec_query(
      "SELECT assessment_id, matched_uprn, matched_confidence FROM scotland.assessments_address_id",
    )
  end
  let(:assessment_address_ids) do
    ActiveRecord::Base.connection.exec_query(
      "SELECT assessment_id, matched_uprn, matched_confidence FROM public.assessments_address_id",
    )
  end

  around do |test|
    original_stage = ENV["STAGE"]
    Events::Broadcaster.enable!
    ENV["STAGE"] = "mock"
    test.run
    Events::Broadcaster.disable!
    ENV["STAGE"] = original_stage
  end

  before(:all) do
    scheme_id = add_scheme_and_get_id
    add_super_assessor(scheme_id:)

    sap_schema = "SAP-Schema-19.1.0".freeze
    sap_xml = Nokogiri.XML Samples.xml(sap_schema, "epc")
    call_lodge_assessment(scheme_id:, schema_name: sap_schema, xml_document: sap_xml, ensure_uprns: false)

    scottish_sap_xml = Samples.xml "SAP-Schema-S-19.0.0"
    scottish_sap_schema = "SAP-Schema-S-19.0.0".freeze
    lodge_assessment assessment_body: scottish_sap_xml,
                     accepted_responses: [201],
                     scopes: %w[assessment:lodge migrate:assessment],
                     auth_data: {
                       scheme_ids: [scheme_id],
                     },
                     schema_name: scottish_sap_schema,
                     migrated: "true"

    schema = "RdSAP-Schema-20.0.0"
    xml = Nokogiri.XML Samples.xml(schema)

    xml.at("RRN").children = "0000-0000-0000-0000-0001"
    call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml, migrated: true)

    xml.at("RRN").children = "0000-0000-0000-0000-0002"
    call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml, migrated: true)

    xml.at("RRN").children = "0000-0000-0000-0000-0003"
    xml.at("Property").at("Address-Line-1").children = ""
    call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml, migrated: true)
  end

  before do
    allow($stdout).to receive(:puts)
    Events::Broadcaster.accept_only! :matched_address
    allow(Gateway::AddressingApiGateway).to receive(:new).and_return(addressing_gateway)
    allow(Gateway::AssessmentsAddressIdGateway).to receive(:new).and_return(assessments_address_id_gateway)
    allow(Gateway::DataWarehouseQueuesGateway).to receive(:new).and_return(data_warehouse_queues_gateway)
    allow(assessments_address_id_gateway).to receive(:update_matched_batch)
    allow(data_warehouse_queues_gateway).to receive(:push_to_queue)
  end

  after do
    ActiveRecord::Base.connection.exec_query(
      "TRUNCATE TABLE assessments CASCADE",
    )
    Events::Broadcaster.accept_any!
  end

  context "when the task runs with a single match for a scottish address" do
    before do
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
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199990129", "address" => "1 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "99.3" },
        ],
      )
      ActiveRecord::Base.connection.exec_query(<<~SQL)
        UPDATE assessments
        SET address_line1 = NULL
        WHERE assessment_id = '0000-0000-0000-0000-0003';
      SQL
    end

    after do
      ActiveRecord::Base.connection.exec_query(<<~SQL)
        UPDATE assessments
        SET address_line1 = ''
        WHERE assessment_id = '0000-0000-0000-0000-0003';
      SQL
    end

    it "calls the addressing api with all parmeters" do
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

  context "when the task run with a single match per address" do
    before do
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
    end
  end

  context "when the task runs with a mixed matched results" do
    before do
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199990129", "address" => "1 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "99.3" },
        ],
        [
          { "uprn" => "199990130", "address" => "1 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "98.3" },
        ],
        [],
      )
      get_task("oneoff:address_match_assessments").invoke
    end

    it "only saves the 2 matched rows" do
      expected_args = ["('0000-0000-0000-0000-0000', '199990129', 99.3)", "('0000-0000-0000-0000-0001', '199990130', 98.3)"], false
      expect(assessments_address_id_gateway).to have_received(:update_matched_batch).with(*expected_args).exactly(1).times
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

    it "updates the assessment_address_id_row" do
      expected_args = ["('0000-0000-0000-0000-0000', '199990144', 90.9)", "('0000-0000-0000-0000-0001', '199990144', 90.9)", "('0000-0000-0000-0000-0002', '199990144', 90.9)", "('0000-0000-0000-0000-0003', '199990144', 90.9)"], false
      get_task("oneoff:address_match_assessments").invoke
      expect(assessments_address_id_gateway).to have_received(:update_matched_batch).with(*expected_args).exactly(1).times
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

    it "updates the assessment_address_id_row" do
      expected_args = ["('0000-0000-0000-0000-0000', 'unknown', 46.2)", "('0000-0000-0000-0000-0001', 'unknown', 46.2)", "('0000-0000-0000-0000-0002', 'unknown', 46.2)", "('0000-0000-0000-0000-0003', 'unknown', 46.2)"], false
      get_task("oneoff:address_match_assessments").invoke
      expect(assessments_address_id_gateway).to have_received(:update_matched_batch).with(*expected_args).exactly(1).times
    end

    it "does not push message to redis" do
      get_task("oneoff:address_match_assessments").invoke
      expect(data_warehouse_queues_gateway).not_to have_received(:push_to_queue)
    end
  end

  context "when there are no matches for the address" do
    before do
      allow(addressing_gateway).to receive(:match_address).and_return([])
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

  context "when calling the task twice for assessments skipping ones with a matched address" do
    before do
      allow($stdout).to receive(:puts)
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199990129", "address" => "1 SOME STREET, SOME AREA, SOME COUNTY, WHITBURY, SW1A 2AA", "confidence" => "99.3" },
        ],
      )
      row = Gateway::AssessmentsAddressIdGateway::AssessmentsAddressId.find("0000-0000-0000-0000-0000")
      row.update_columns(matched_uprn: "199990129")
      row = Gateway::AssessmentsAddressIdGateway::AssessmentsAddressId.find("0000-0000-0000-0000-0001")
      row.update_columns(matched_uprn: "199990129")
      row = Gateway::AssessmentsAddressIdGateway::AssessmentsAddressId.find("0000-0000-0000-0000-0003")
      row.update_columns(matched_uprn: "199990129")
      get_task("oneoff:address_match_assessments").invoke
    end

    before(:all) do
      EnvironmentStub.with("SKIP_EXISTING", "true")
    end

    after(:all) do
      EnvironmentStub.remove(%w[SKIP_EXISTING])
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
      get_task("oneoff:address_match_assessments").invoke
      expect(assessments_address_id_gateway).not_to have_received(:update_matched_batch)
    end

    it "processes the assessments inside the range" do
      EnvironmentStub.with("DATE_FROM", "2022-05-01")
      EnvironmentStub.with("DATE_TO", "2023-05-01")
      get_task("oneoff:address_match_assessments").invoke
      expect(assessments_address_id_gateway).to have_received(:update_matched_batch).exactly(1).times
    end
  end

  context "when the number of EPCs is greater than the batch size" do
    let(:assessments_address_id_gateway) do
      instance_double(Gateway::AssessmentsAddressIdGateway)
    end

    let(:data_warehouse_queues_gateway) do
      instance_double(Gateway::DataWarehouseQueuesGateway)
    end

    before do
      allow(addressing_gateway).to receive(:match_address).and_return(
        [
          { "uprn" => "199990128", "address" => "1A Some Street, Some Area, Some County, Whitbury, SW1A 2AA", "confidence" => "46.2" },
        ],
        [
          { "uprn" => "199990179", "address" => "1A Some Street, Some Area, Some County, Whitbury, SW1A 2AA", "confidence" => "76.2" },
        ],
        [
          { "uprn" => "199990126", "address" => "1A Some Street, Some Area, Some County, Whitbury, SW1A 2AA", "confidence" => "54.2" },
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
      expect(assessments_address_id_gateway).to have_received(:update_matched_batch).with(["('0000-0000-0000-0000-0000', '199990128', 46.2)", "('0000-0000-0000-0000-0001', '199990179', 76.2)"], false).exactly(1).times
      expect(assessments_address_id_gateway).to have_received(:update_matched_batch).with(["('0000-0000-0000-0000-0002', '199990126', 54.2)", "('0000-0000-0000-0000-0003', '199990126', 54.2)"], false).exactly(1).times
    end

    it "sends the sliced payload to Redis" do
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).with(:backfill_matched_address_update, %w[0000-0000-0000-0000-0000:199990128 0000-0000-0000-0000-0001:199990179]).exactly(1).times
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).with(:backfill_matched_address_update, ["0000-0000-0000-0000-0002:199990126", "0000-0000-0000-0000-0003:199990126"]).exactly(1).times
    end
  end
end
