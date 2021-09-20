describe "syncing to data warehouse on various assessment data changes" do
  include RSpecRegisterApiServiceMixin

  let(:redis_gateway) { instance_spy(Gateway::RedisGateway) }

  assessment_id = nil

  around do |test|
    EventBroadcaster.enable!
    test.run
    EventBroadcaster.disable!
  end

  before do
    allow(Helper::Toggles).to receive(:enabled?)
    allow(Helper::Toggles).to receive(:enabled?).with("sync_to_data_warehouse").and_return(true)
  end

  after do
    EventBroadcaster.accept_any!
  end

  context "when an assessment is lodged" do
    before do
      allow(Gateway::RedisGateway).to receive(:new).and_return(redis_gateway)

      scheme_id = add_scheme_and_get_id
      assessor =
        AssessorStub.new.fetch_request_body(
          domestic_rd_sap: "ACTIVE",
          domestic_sap: "ACTIVE",
        )
      add_assessor scheme_id: scheme_id,
                   assessor_id: "SPEC000000",
                   body: assessor
      xml_doc = Samples.xml "SAP-Schema-18.0.0"
      assessment_id = Nokogiri.XML(xml_doc).at("RRN").content
      lodge_assessment assessment_body: xml_doc,
                       auth_data: {
                         scheme_ids: [scheme_id],
                       },
                       schema_name: "SAP-Schema-18.0.0"
    end

    it "pushes the assessment ID to the assessments queue through the gateway" do
      expect(redis_gateway).to have_received(:push_to_queue).with(:assessments, assessment_id)
    end
  end

  context "when an assessment is opted out" do
    before do
      allow(Gateway::RedisGateway).to receive(:new).and_return(redis_gateway)

      EventBroadcaster.accept_only! :assessment_opt_out_status_changed

      scheme_id = add_scheme_and_get_id
      assessor =
        AssessorStub.new.fetch_request_body(
          domestic_rd_sap: "ACTIVE",
          domestic_sap: "ACTIVE",
        )
      add_assessor scheme_id: scheme_id,
                   assessor_id: "SPEC000000",
                   body: assessor
      xml_doc = Samples.xml "SAP-Schema-18.0.0"
      assessment_id = Nokogiri.XML(xml_doc).at("RRN").content
      lodge_assessment assessment_body: xml_doc,
                       auth_data: {
                         scheme_ids: [scheme_id],
                       },
                       schema_name: "SAP-Schema-18.0.0"
      opt_out_assessment assessment_id: assessment_id,
                         opt_out: true
    end

    it "pushes the assessment ID to the opt outs queue through the gateway" do
      expect(redis_gateway).to have_received(:push_to_queue).with(:opt_outs, assessment_id)
    end
  end

  context "when an assessment's address ID is changed" do
    let(:new_address_id) { "UPRN-000000000123" }

    before do
      allow(Gateway::RedisGateway).to receive(:new).and_return(redis_gateway)

      EventBroadcaster.accept_only! :assessment_address_id_updated

      add_uprns_to_address_base new_address_id[-3, 3]

      scheme_id = add_scheme_and_get_id
      assessor =
        AssessorStub.new.fetch_request_body(
          domestic_rd_sap: "ACTIVE",
          domestic_sap: "ACTIVE",
        )
      add_assessor scheme_id: scheme_id,
                   assessor_id: "SPEC000000",
                   body: assessor
      xml_doc = Samples.xml "SAP-Schema-18.0.0"
      assessment_id = Nokogiri.XML(xml_doc).at("RRN").content
      lodge_assessment assessment_body: xml_doc,
                       auth_data: {
                         scheme_ids: [scheme_id],
                       },
                       schema_name: "SAP-Schema-18.0.0"
      update_assessment_address_id assessment_id: assessment_id,
                                   new_address_id: new_address_id
    end

    it "pushes the assessment ID to the assessments queue through the gateway" do
      expect(redis_gateway).to have_received(:push_to_queue).with(:assessments, assessment_id)
    end
  end

  context "when an assessment is cancelled" do
    before do
      allow(Gateway::RedisGateway).to receive(:new).and_return(redis_gateway)

      EventBroadcaster.accept_only! :assessment_cancelled, :assessment_marked_not_for_issue

      scheme_id = add_scheme_and_get_id
      assessor =
        AssessorStub.new.fetch_request_body(
          domestic_rd_sap: "ACTIVE",
          domestic_sap: "ACTIVE",
        )
      add_assessor scheme_id: scheme_id,
                   assessor_id: "SPEC000000",
                   body: assessor
      xml_doc = Samples.xml "SAP-Schema-18.0.0"
      assessment_id = Nokogiri.XML(xml_doc).at("RRN").content
      lodge_assessment assessment_body: xml_doc,
                       auth_data: {
                         scheme_ids: [scheme_id],
                       },
                       schema_name: "SAP-Schema-18.0.0"
      update_assessment_status assessment_id: assessment_id,
                               assessment_status_body: {
                                 status: "CANCELLED",
                               },
                               accepted_responses: [200, 201],
                               auth_data: {
                                 scheme_ids: [scheme_id],
                               }
    end

    it "pushes the assessment ID to the cancelled queue through the gateway" do
      expect(redis_gateway).to have_received(:push_to_queue).with(:cancelled, assessment_id)
    end
  end
end
