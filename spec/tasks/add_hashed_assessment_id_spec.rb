describe "add hashed assessment_id rake" do
  include RSpecRegisterApiServiceMixin

  let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }
  let(:valid_rdsap_ni_xml) { Samples.xml "RdSAP-Schema-NI-20.0.0" }
  let(:valid_cepc_xml) { Samples.xml "CEPC-8.0.0", "cepc" }
  let(:valid_dec_xml) { Samples.xml "CEPC-8.0.0", "dec" }

  let(:scheme_id) { add_scheme_and_get_id }

  let(:add_hashed_assessment_id_rake) { get_task("data_export:add_hashed_assessment_id") }

  context "when adding a hashed_assessment_id for a batch of certificates" do
    before do
      add_super_assessor(scheme_id:)
      rdsap_xml = Nokogiri.XML valid_rdsap_xml
      rdsap_xml.at("Registration-Date").children = "2022-09-11"
      lodge_assessment(
        assessment_body: rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
      )
      rdsap_xml = Nokogiri.XML valid_rdsap_xml
      rdsap_xml.at("RRN").children = "1234-5678-1234-2278-1111"
      rdsap_xml.at("Registration-Date").children = "2022-09-05"
      lodge_assessment(
        assessment_body: rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
      )
      rdsap_ni_xml = Nokogiri.XML valid_rdsap_ni_xml
      rdsap_ni_xml.at("RRN").children = "1234-5678-1234-2278-1234"
      rdsap_ni_xml.at("Registration-Date").children = "2022-09-11"
      lodge_assessment(
        assessment_body: rdsap_ni_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
        schema_name: "RdSAP-Schema-NI-20.0.0",
      )
      cepc_xml = Nokogiri.XML valid_cepc_xml
      cepc_xml.at("//CEPC:RRN").children = "1234-5678-1234-2278-2345"
      cepc_xml.at("//CEPC:Registration-Date").children = "2022-09-11"
      lodge_assessment(
        assessment_body: cepc_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
        schema_name: "CEPC-8.0.0",
      )
      dec_xml = Nokogiri.XML valid_dec_xml
      dec_xml.at("RRN").children = "1234-5678-1234-2278-3456"
      dec_xml.at("Registration-Date").children = "2022-09-11"
      lodge_assessment(
        assessment_body: dec_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
        schema_name: "CEPC-8.0.0",
      )
      ActiveRecord::Base.connection.execute "UPDATE assessments SET hashed_assessment_id = NULL"
    end

    context "and are RdSAP and RdSAP NI" do
      before do
        add_hashed_assessment_id_rake.invoke("2022-09-11", "2022-09-13", "RdSAP")
      end

      let(:assessment_data) do
        (ActiveRecord::Base
                               .connection.execute "SELECT assessment_id, hashed_assessment_id, date_registered FROM assessments WHERE hashed_assessment_id IS NOT NULL")
      end
      let(:rdsap_hashed_assessment_id) { assessment_data.to_a.find { |h| break h["hashed_assessment_id"] if h["assessment_id"] == "0000-0000-0000-0000-0000" } }
      let(:rdsap_ni_hashed_assessment_id) { assessment_data.to_a.find { |h| break h["hashed_assessment_id"] if h["assessment_id"] == "1234-5678-1234-2278-1234" } }
      let(:rdsap_date_registered) { assessment_data.to_a.find { |h| break h["date_registered"] if h["assessment_id"] == "0000-0000-0000-0000-0000" } }
      let(:rdsap_ni_date_registered) { assessment_data.to_a.find { |h| break h["date_registered"] if h["assessment_id"] == "1234-5678-1234-2278-1234" } }

      it "only updated RdSAP certificates in the date range" do
        expect(assessment_data.count).to eq 2
        expect(rdsap_date_registered).to eq("2022-09-11 00:00:00.000000000 +0000")
        expect(rdsap_ni_date_registered).to eq("2022-09-11 00:00:00.000000000 +0000")
      end

      it "will always generate the same expected hash" do
        expect(rdsap_hashed_assessment_id).to eq("4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a")
        expect(rdsap_ni_hashed_assessment_id).to eq("3219a657a59c669870b97a97a00fd722b81dbb02ffed384e794782f4991a5687")
      end
    end

    it "updates the hashed_assessment_id for CEPC columns" do
      add_hashed_assessment_id_rake.invoke("2022-09-11", "2022-09-13", "CEPC")

      assessment_data =
        (ActiveRecord::Base
           .connection.execute "SELECT assessment_id, hashed_assessment_id FROM assessments WHERE hashed_assessment_id IS NOT NULL")

      expect(assessment_data.count).to eq 1
      expect(assessment_data.first["hashed_assessment_id"]).to eq("072565c3bef87ff11df01d0f0d42755ed89abcabed94798863e652aaf4b4fb1b")
    end

    it "updates the hashed_assessment_id for DEC columns" do
      add_hashed_assessment_id_rake.invoke("2022-09-11", "2022-09-13", "DEC")

      assessment_data =
        (ActiveRecord::Base
           .connection.execute "SELECT assessment_id, hashed_assessment_id FROM assessments WHERE hashed_assessment_id IS NOT NULL")

      expect(assessment_data.count).to eq 1
      expect(assessment_data.first["hashed_assessment_id"]).to eq("20d5d5e324ae340cfd34a59adf19a822a76a7305dedcc5130674c6dd1cb35642")
    end

    it "returns a no data to export error when missing date_from argument" do
      expected_message =
        "A required argument is missing: date_from"

      expect { add_hashed_assessment_id_rake.invoke(nil, "2022-09-13", "DEC") }.to raise_error(Boundary::ArgumentMissing).with_message(expected_message)
    end

    it "returns a no data to export error when missing date_to argument" do
      expected_message =
        "A required argument is missing: date_to"

      expect { add_hashed_assessment_id_rake.invoke("2022-09-13", nil, "DEC") }.to raise_error(Boundary::ArgumentMissing).with_message(expected_message)
    end

    it "returns a no data to export error when missing assessment_type argument" do
      expected_message =
        "A required argument is missing: assessment_type, eg: 'SAP-RDSAP', 'DEC' etc"

      expect { add_hashed_assessment_id_rake.invoke("2022-09-13", "2022-09-13", nil) }.to raise_error(Boundary::ArgumentMissing).with_message(expected_message)
    end

    it "returns a no data to export error when date_from is later thank date_to" do
      expect { add_hashed_assessment_id_rake.invoke("2022-09-13", "2022-09-11", "DEC") }.to raise_error(Boundary::InvalidDates)
    end

    context "when passing the rake arguments as environmental variables" do
      before do
        EnvironmentStub.with("date_from", "2022-09-01")
        EnvironmentStub.with("date_to", "2022-09-11")
        EnvironmentStub.with("assessment_type", "DEC")
      end

      after do
        EnvironmentStub.remove(%w[date_from date_to assessment_type])
      end

      it "does not raise an error" do
        expect { add_hashed_assessment_id_rake.invoke }.not_to raise_error
      end
    end
  end
end
