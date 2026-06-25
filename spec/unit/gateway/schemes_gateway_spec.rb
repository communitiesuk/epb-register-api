describe Gateway::SchemesGateway do
  subject(:gateway) { described_class.new }

  describe "#fetch_active" do
    context "when there are active and inactive schemes" do
      before do
        ActiveRecord::Base.connection.exec_query("INSERT INTO schemes (scheme_id, active, active_scotland, active_eng_wls_nir) VALUES ('1',false, true, true)")
        ActiveRecord::Base.connection.exec_query("INSERT INTO schemes (scheme_id, active, active_scotland, active_eng_wls_nir) VALUES ('2',true, true, true)")
        ActiveRecord::Base.connection.exec_query("INSERT INTO schemes (scheme_id, active, active_scotland, active_eng_wls_nir) VALUES ('3',true, true, true)")
        ActiveRecord::Base.connection.exec_query("INSERT INTO schemes (scheme_id, active, active_scotland, active_eng_wls_nir) VALUES ('4',true, true, true)")
      end

      it "returns only active scheme_ids" do
        expect(gateway.fetch_active.sort).to eq([2, 3, 4])
      end
    end
  end

  describe "#add" do
    context "when the scheme does not already exist" do
      it "is added to the scheme table" do
        gateway.add({ name: "test_scheme", active: true, active_scotland: true, active_eng_wls_nir: true })
        scheme = ActiveRecord::Base.connection.exec_query("SELECT * FROM schemes WHERE name = 'test_scheme'")
        expect(scheme.result.first).to include({ "name" => "test_scheme", "active" => true, "active_scotland" => true, "active_eng_wls_nir" => true })
      end
    end

    context "when the scheme does already exist" do
      it "is raises an error" do
        scheme_body = { name: "test_scheme", active: true, active_scotland: true, active_eng_wls_nir: true }
        gateway.add(scheme_body)
        expect { gateway.add(scheme_body) }.to raise_error Gateway::SchemesGateway::DuplicateSchemeException
      end
    end
  end

  describe "#update" do
    context "when the scheme already exist" do
      it "updates the scheme entry" do
        gateway.add({ name: "test_scheme", active: true, active_scotland: true, active_eng_wls_nir: true })
        scheme = ActiveRecord::Base.connection.exec_query("SELECT * FROM schemes WHERE name = 'test_scheme'")
        scheme_id = scheme.result.first["scheme_id"]
        gateway.update(scheme_id, { name: "test_scheme", active: false, active_scotland: false, active_eng_wls_nir: false })
        updated_scheme = ActiveRecord::Base.connection.exec_query("SELECT * FROM schemes WHERE name = 'test_scheme'")

        expect(updated_scheme.result.first).to include({ "name" => "test_scheme", "active" => false, "active_scotland" => false, "active_eng_wls_nir" => false, "scheme_id" => scheme_id })
      end
    end

    context "when the scheme does not already exist" do
      it "is raises an error" do
        expect { gateway.update("1", { name: "test_scheme", active: false, active_scotland: false, active_eng_wls_nir: false }) }.to raise_error Gateway::SchemesGateway::SchemeNotPresentException
      end
    end
  end
end
