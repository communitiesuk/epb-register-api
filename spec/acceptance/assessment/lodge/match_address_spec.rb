describe "Acceptance::MatchAddress", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  let(:rdsap_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/RdSAP-20.0.0.xml"
  end

  let(:scheme_id) { add_scheme_and_get_id }

  let(:assessments_address_id) do
    ActiveRecord::Base.connection.exec_query(
      "SELECT * FROM assessments_address_id",
    )
  end

  describe "when lodging an assessment" do
    let(:addressing_api_response) do
      [
        {
          "uprn" => "123412341234",
          "address" => "1 Some addresss",
          "confidence" => 99.7,
        },
      ]
    end

    let(:addressing_gateway) do
      instance_double(Gateway::AddressingApiGateway)
    end

    before do
      add_assessor(
        scheme_id:,
        assessor_id: "JASE000000",
        body: AssessorStub.new.fetch_request_body(
          non_domestic_nos3: "ACTIVE",
          non_domestic_nos4: "ACTIVE",
          non_domestic_nos5: "ACTIVE",
          non_domestic_dec: "ACTIVE",
          non_domestic_sp3: "ACTIVE",
          non_domestic_cc4: "ACTIVE",
          domestic_sap: "ACTIVE",
          domestic_rd_sap: "ACTIVE",
        ),
      )

      allow(Gateway::AddressingApiGateway).to receive(:new).and_return(addressing_gateway)
      allow(addressing_gateway).to receive(:match_address)
                          .and_return(addressing_api_response)
    end

    around do |test|
      Events::Broadcaster.enable!
      test.run
      Events::Broadcaster.disable!
    end

    context "when the address-matching-during-lodgement flag is enabled" do
      let(:expected_result) do
        {
          "address_id" => "UPRN-000000000000",
          "address_updated_at" => nil,
          "assessment_id" => "0000-0000-0000-0000-0000",
          "matched_address_id" => "123412341234",
          "matched_confidence" => 99.7,
          "source" => "lodgement",
        }
      end

      before do
        allow_any_instance_of(Events::Listener).to receive(:address_matching_during_lodgement_enabled?).and_return(true)

        lodge_assessment(
          assessment_body: rdsap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )
      end

      it "updates matched address_id and confidence values" do
        expect(assessments_address_id.first).to eq(expected_result)
      end
    end

    context "when the addressing api responds with an error" do
      let(:unmatched_result) do
        {
          "address_id" => "UPRN-000000000000",
          "address_updated_at" => nil,
          "assessment_id" => "0000-0000-0000-0000-0000",
          "matched_address_id" => nil,
          "matched_confidence" => nil,
          "source" => "lodgement",
        }
      end

      before do
        allow_any_instance_of(Events::Listener).to receive(:address_matching_during_lodgement_enabled?).and_return(true)

        allow(addressing_gateway).to receive(:match_address).and_raise(Errors::ApiResponseError)
        allow($stdout).to receive(:write)
      end

      it "sends the error to the logs" do
        expect {
          lodge_assessment(
            assessment_body: rdsap_xml,
            accepted_responses: [201],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            schema_name: "RdSAP-Schema-20.0.0",
          )
        }.to output(
          /Event broadcaster caught Errors::ApiResponseError/,
        ).to_stdout_from_any_process
      end

      it "does not update matched address_id or confidence" do
        lodge_assessment(
          assessment_body: rdsap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )
        expect(assessments_address_id.first).to eq(unmatched_result)
      end
    end

    context "when the address-matching-during-lodgement flag is disabled" do
      let(:unmatched_result) do
        {
          "address_id" => "UPRN-000000000000",
          "address_updated_at" => nil,
          "assessment_id" => "0000-0000-0000-0000-0000",
          "matched_address_id" => nil,
          "matched_confidence" => nil,
          "source" => "lodgement",
        }
      end

      before do
        allow_any_instance_of(Events::Listener).to receive(:address_matching_during_lodgement_enabled?).and_return(false)

        lodge_assessment(
          assessment_body: rdsap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )
      end

      it "does not update matched address_id or confidence" do
        expect(assessments_address_id.first).to eq(unmatched_result)
      end
    end
  end
end
