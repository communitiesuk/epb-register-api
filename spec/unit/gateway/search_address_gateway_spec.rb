describe Gateway::SearchAddressGateway, set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new }

  let(:record) do
    {
      assessment_id: "0000-0000-0000-0000-0005",
      address: {
        address_id: "UPRN-000000000123",
        address_line1: "22 Acacia Avenue",
        address_line2: "some place",
        address_line3: "",
        address_line4: "",
        town: "Anytown",
        postcode: "AB1 2CD",
      },
    }
  end

  let(:search_address) { Domain::SearchAddress.new record }

  describe "#insert" do
    it "saves data to the search address table without error" do
      expect { gateway.insert search_address.to_hash }.not_to raise_error
    end

    it "the saved data is correct" do
      gateway.insert search_address.to_hash
      saved_data = ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_search_address")
      expect(saved_data.rows.length).to eq 1
      expect(saved_data[0]["assessment_id"]).to eq "0000-0000-0000-0000-0005"
      expect(saved_data[0]["address"]).to eq "22 acacia avenue some place"
    end

    it "does not duplicate rows" do
      gateway.insert search_address.to_hash
      gateway.insert search_address.to_hash
      saved_data = ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_search_address")
      expect(saved_data.rows.length).to eq 1
    end
  end

  describe "#bulk_insert" do
    let(:scheme_id) { add_scheme_and_get_id }

    let(:rdsap_xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }

    before do
      add_super_assessor(scheme_id:)

      do_lodgement = lambda {
        lodge_assessment(
          assessment_body: rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )
      }
      do_lodgement.call
      rdsap_xml.at("RRN").content = "0000-0000-0000-0000-9999"
      do_lodgement.call
      rdsap_xml.at("RRN").content = "0000-0000-0000-9999-9999"
      do_lodgement.call
      ActiveRecord::Base.connection.exec_query("TRUNCATE TABLE assessment_search_address")
    end

    it "saves assessments to the search address table without error" do
      expect { gateway.bulk_insert }.not_to raise_error
    end

    it "saves the 3 assessments from the assessments table to the search address table" do
      gateway.bulk_insert
      saved_data = ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_search_address")
      expect(saved_data.rows.length).to eq 3
    end

    it "does not duplicate rows if the bulk insert is run again" do
      gateway.bulk_insert
      gateway.bulk_insert
      saved_data = ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_search_address")
      expect(saved_data.rows.length).to eq 3
    end

    it "doesn't contain empty spaces when there are empty address lines" do
      ActiveRecord::Base.connection.exec_query("UPDATE assessments SET address_line4='Student Village' WHERE assessment_id='0000-0000-0000-0000-0000'")
      gateway.bulk_insert
      saved_data = ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_search_address WHERE assessment_id='0000-0000-0000-0000-0000'")
      expect(saved_data[0]["assessment_id"]).to eq "0000-0000-0000-0000-0000"
      expect(saved_data[0]["address"]).to eq "1 some street student village"
    end
  end
end
