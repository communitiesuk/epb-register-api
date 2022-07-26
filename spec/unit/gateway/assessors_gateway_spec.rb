describe Gateway::AssessorsGateway do
  include RSpecRegisterApiServiceMixin
  subject(:gateway) { described_class.new }

  describe "#search_by" do
    context "when there are more than 20 assessors of the same name" do
      before do
        scheme_id = add_scheme_and_get_id
        11.upto(31) do |n|
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
            ),
          )
        end
      end

      it "returns more than 20 items of the same name " do
        expect(gateway.search_by(name: "Someone Person").length).to eq(21)
      end
    end
  end
end
