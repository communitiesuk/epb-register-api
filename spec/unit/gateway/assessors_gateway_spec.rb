describe Gateway::AssessorsGateway do
  include RSpecRegisterApiServiceMixin
  subject(:gateway) { described_class.new }

  before do
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

    ActiveRecord::Base.connection.execute(
      "INSERT INTO postcode_geolocation (postcode, latitude, longitude) VALUES('AB1 0AA', '57.101459','-2.242858'), ('AA1 0AA', '56.101459','-1.241858')",
    )
  end

  describe "#search_by" do
    context "when there are more than 20 assessors of the same name" do
      it "returns more than 20 items of the same name" do
        expect(gateway.search_by(name: "Someone Person").length).to eq(21)
      end
    end
  end

  describe "#search" do
    context "when searching for a English assessor by postcode" do
      it "returns only assessors with English qualification details" do
        expect(gateway.search("56.101459", "-1.241858", %w[domesticRdSap]).length).to eq(6)
        expect(gateway.search("56.101459", "-1.241858", %w[domesticRdSap]).first[:qualifications][:domestic_rd_sap]).to eq("ACTIVE")
        expect(gateway.search("56.101459", "-1.241858", %w[domesticRdSap]).first[:qualifications][:scotland_rdsap]).to eq("INACTIVE")
      end
    end

    context "when searching for a Scottish assessor by postcode" do
      it "returns only assessors with Scottish qualification details" do
        expect(gateway.search("57.101453", "-2.242828", %w[scotlandSapExistingBuilding], is_scottish: true).length).to eq(6)
        expect(gateway.search("57.101453", "-2.242828", %w[scotlandSapExistingBuilding], is_scottish: true).first[:qualifications][:domestic_rd_sap]).to eq("INACTIVE")
        expect(gateway.search("57.101453", "-2.242828", %w[scotlandSapExistingBuilding], is_scottish: true).first[:qualifications][:scotland_rdsap]).to eq("ACTIVE")
      end
    end
  end
end
