require_relative "../../shared_context/shared_scottish_assessors"

describe Gateway::AssessorsGateway do
  include RSpecRegisterApiServiceMixin
  subject(:gateway) { described_class.new }

  before(:all) do
    scheme_id = add_scheme_and_get_id
    11.upto(16) do |n|
      add_assessor(
        scheme_id:,
        assessor_id: "ACME1234#{n}",
        body: AssessorStub.new.fetch_request_body(
          non_domestic_nos3: "ACTIVE",
          non_domestic_nos4: "ACTIVE",
          non_domestic_nos5: "ACTIVE",
          non_domestic_dec: "ACTIVE",
          domestic_rd_sap: "ACTIVE",
          domestic_sap: "ACTIVE",
          non_domestic_sp3: "ACTIVE",
          non_domestic_cc4: "ACTIVE",
          gda: "ACTIVE",
          scotland_dec_and_ar: "INACTIVE",
          scotland_nondomestic_existing_building: "INACTIVE",
          scotland_nondomestic_new_building: "INACTIVE",
          scotland_rdsap: "INACTIVE",
          scotland_sap_existing_building: "INACTIVE",
          scotland_sap_new_building: "INACTIVE",
          scotland_section63: "INACTIVE",
          search_results_comparison_postcode: "AA1 0AA",
        ),
      )
    end

    17.upto(21) do |n|
      add_assessor(
        scheme_id:,
        assessor_id: "ACME1234#{n}",
        body: AssessorStub.new.fetch_request_body(
          non_domestic_nos3: "ACTIVE",
          non_domestic_nos4: "ACTIVE",
          non_domestic_nos5: "ACTIVE",
          non_domestic_dec: "ACTIVE",
          domestic_rd_sap: "ACTIVE",
          domestic_sap: "ACTIVE",
          non_domestic_sp3: "ACTIVE",
          non_domestic_cc4: "ACTIVE",
          gda: "ACTIVE",
          scotland_dec_and_ar: "INACTIVE",
          scotland_nondomestic_existing_building: "INACTIVE",
          scotland_nondomestic_new_building: "INACTIVE",
          scotland_rdsap: "INACTIVE",
          scotland_sap_existing_building: "INACTIVE",
          scotland_sap_new_building: "INACTIVE",
          scotland_section63: "INACTIVE",
          search_results_comparison_postcode: "AB1 0AA",
        ),
      )
    end

    22.upto(25) do |n|
      add_assessor(
        scheme_id:,
        assessor_id: "ACME1234#{n}",
        body: AssessorStub.new.fetch_request_body(
          non_domestic_nos3: "INACTIVE",
          non_domestic_nos4: "INACTIVE",
          non_domestic_nos5: "INACTIVE",
          non_domestic_dec: "INACTIVE",
          domestic_rd_sap: "INACTIVE",
          domestic_sap: "INACTIVE",
          non_domestic_sp3: "INACTIVE",
          non_domestic_cc4: "INACTIVE",
          gda: "INACTIVE",
          scotland_dec_and_ar: "ACTIVE",
          scotland_nondomestic_existing_building: "ACTIVE",
          scotland_nondomestic_new_building: "ACTIVE",
          scotland_rdsap: "ACTIVE",
          scotland_sap_existing_building: "ACTIVE",
          scotland_sap_new_building: "ACTIVE",
          scotland_section63: "ACTIVE",
          search_results_comparison_postcode: "AA1 0AA",
        ),
      )
    end

    26.upto(31) do |n|
      add_assessor(
        scheme_id:,
        assessor_id: "ACME1234#{n}",
        body: AssessorStub.new.fetch_request_body(
          non_domestic_nos3: "INACTIVE",
          non_domestic_nos4: "INACTIVE",
          non_domestic_nos5: "INACTIVE",
          non_domestic_dec: "INACTIVE",
          domestic_rd_sap: "INACTIVE",
          domestic_sap: "INACTIVE",
          non_domestic_sp3: "INACTIVE",
          non_domestic_cc4: "INACTIVE",
          gda: "INACTIVE",
          scotland_dec_and_ar: "ACTIVE",
          scotland_nondomestic_existing_building: "ACTIVE",
          scotland_nondomestic_new_building: "ACTIVE",
          scotland_rdsap: "ACTIVE",
          scotland_sap_existing_building: "ACTIVE",
          scotland_sap_new_building: "ACTIVE",
          scotland_section63: "ACTIVE",
          search_results_comparison_postcode: "AB1 0AA",
        ),
      )
    end

    add_assessor(
      scheme_id:,
      assessor_id: "ACME123432",
      body: AssessorStub.new.fetch_request_body(
        first_name: "Alfie",
        last_name: "Betts",
        non_domestic_nos3: "INACTIVE",
        non_domestic_nos4: "INACTIVE",
        non_domestic_nos5: "INACTIVE",
        non_domestic_dec: "INACTIVE",
        domestic_rd_sap: "INACTIVE",
        domestic_sap: "INACTIVE",
        non_domestic_sp3: "INACTIVE",
        non_domestic_cc4: "INACTIVE",
        gda: "INACTIVE",
        scotland_dec_and_ar: "ACTIVE",
        scotland_nondomestic_existing_building: "ACTIVE",
        scotland_nondomestic_new_building: "ACTIVE",
        scotland_rdsap: "ACTIVE",
        scotland_sap_existing_building: "ACTIVE",
        scotland_sap_new_building: "ACTIVE",
        scotland_section63: "ACTIVE",
        search_results_comparison_postcode: "AB1 0AA",
      ),
    )

    ActiveRecord::Base.connection.execute(<<~SQL.squish)
      INSERT INTO postcode_geolocation (postcode, latitude, longitude, region)
      VALUES ('AB1 0AA', '57.101459','-2.242858', 'Scotland'),
             ('AA1 0AA', '56.101459','-1.241858', 'South West')
    SQL
  end

  describe "#search_by" do
    context "when there are more than 20 assessors of the same name" do
      it "returns more than 20 items of the same name" do
        expect(gateway.search_by(name: "Someone Person").length).to eq(21)
      end
    end

    context "when you search by name for an assessor who only has Scottish qualifications active" do
      it "does not return them" do
        expect(gateway.search_by(name: "Alfie Betts", qualification_type: "domestic").length).to eq(0)
      end
    end
  end

  describe "#search" do
    context "when searching for a English assessor by postcode" do
      it "returns only assessors with English qualification details" do
        expect(gateway.search("56.101459", "-1.241858", %w[domesticRdSap]).length).to eq(6)
        expect(gateway.search("56.101459", "-1.241858", %w[domesticRdSap]).first[:qualifications][:domestic_rd_sap]).to eq("ACTIVE")
        expect(gateway.search("56.101459", "-1.241858", %w[domesticRdSap]).first[:qualifications]).not_to include(:scotland_rdsap)
      end
    end

    context "when searching for a Scottish assessor by postcode" do
      it "returns only assessors with Scottish qualification details" do
        expect(gateway.search("57.101453", "-2.242828", %w[scotlandSapExistingBuilding], is_scottish: true).length).to eq(7)
        expect(gateway.search("57.101453", "-2.242828", %w[scotlandSapExistingBuilding], is_scottish: true).first[:qualifications]).not_to include(:domestic_rd_sap)
        expect(gateway.search("57.101453", "-2.242828", %w[scotlandSapExistingBuilding], is_scottish: true).first[:qualifications][:scotland_rdsap]).to eq("ACTIVE")
      end
    end
  end

  describe "#search_by_date" do
    include_context "when testing Scottish assessors"

    let(:start_date) do
      Time.now.strftime("%Y-%m-%d")
    end

    let(:limit) { 50 }
    let(:current_page) { 1 }

    let(:end_date) do
      (Time.now + 1.day).strftime("%Y-%m-%d")
    end

    let(:args) do
      { start_date:, end_date:, limit:, current_page: }
    end

    let(:expected_result) do
      {
        first_name: "Someone",
        last_name: "Person",
        scheme_assessor_id: "ACME123423",
        qualifications: {
          scotland_rdsap: "ACTIVE",
          scotland_sap_existing_building: "ACTIVE",
          scotland_sap_new_building: "ACTIVE",
          scotland_dec_and_ar: "ACTIVE",
          scotland_nondomestic_existing_building: "ACTIVE",
          scotland_nondomestic_new_building: "ACTIVE",
          scotland_section63: "ACTIVE",
        },

      }
    end

    before do
      add_assessors_to_logs

      allow(Helper::PaginationHelper).to receive(:calculate_offset)
    end

    it "returns assessors with Scottish qualifications added within a date range" do
      expect(gateway.search_by_date(**args).length).to eq(11)
    end

    it "calculates the offset by calling the Helper class method" do
      gateway.search_by_date(**args)
      expect(Helper::PaginationHelper).to have_received(:calculate_offset).with(1, 50)
    end

    it "does not return assessors with inactive Scottish qualification" do
      ActiveRecord::Base.connection.exec_query(
        "UPDATE assessors SET scotland_dec_and_ar_qualification = 'INACTIVE',
              scotland_nondomestic_existing_building_qualification = 'INACTIVE',
              scotland_nondomestic_new_building_qualification = 'INACTIVE',
              scotland_rdsap_qualification = 'INACTIVE',
              scotland_sap_existing_building_qualification = 'INACTIVE',
              scotland_sap_new_building_qualification = 'INACTIVE',
              scotland_section63_qualification = 'INACTIVE'
        WHERE scheme_assessor_id IN ('ACME123422', 'ACME123426', 'ACME123428')",
      )

      expect(gateway.search_by_date(**args).length).to eq(8)
    end

    it "returns the expected keys for the assessors returned" do
      result = gateway.search_by_date(**args).find { |i| i[:scheme_assessor_id] == "ACME123423" }
      expect(result).to eq(expected_result)
    end

    it "limits the results" do
      args[:limit] = 2
      result = gateway.search_by_date(**args)
      expect(result.length).to eq(2)
    end
  end

  describe "#count_search_by_date" do
    include_context "when testing Scottish assessors"
    before do
      add_assessors_to_logs
    end

    let(:start_date) do
      Time.now.strftime("%Y-%m-%d")
    end

    let(:end_date) do
      (Time.now + 1.day).strftime("%Y-%m-%d")
    end

    let(:args) do
      { start_date:, end_date: }
    end

    it "returns the count of assessors by date" do
      expect(gateway.count_search_by_date(**args)).to eq(11)
    end

    context "when no assessors are found in the date range" do
      args = { start_date: "2014-12-25", end_date: "2014-12-27" }

      it "returns a zero" do
        expect(gateway.count_search_by_date(**args)).to eq(0)
      end
    end
  end
end
