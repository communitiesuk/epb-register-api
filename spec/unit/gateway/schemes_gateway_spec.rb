describe Gateway::SchemesGateway do
  subject(:gateway) { described_class.new }

  describe "#fetch_active" do
    context "when there are active and inactive schemes" do
      before do
        ActiveRecord::Base.connection.exec_query("INSERT INTO schemes (scheme_id) VALUES ('1')")
        ActiveRecord::Base.connection.exec_query("INSERT INTO schemes (scheme_id) VALUES ('2')")
        ActiveRecord::Base.connection.exec_query("INSERT INTO schemes (scheme_id) VALUES ('3')")
        ActiveRecord::Base.connection.exec_query("INSERT INTO schemes (scheme_id) VALUES ('4')")
        ActiveRecord::Base.connection.exec_query("UPDATE schemes SET active=false WHERE scheme_id = '1'")
      end

      it "returns only active scheme_ids" do
        expect(gateway.fetch_active).to eq([2, 3, 4])
      end
    end
  end
end
