describe Gateway::AssessmentsGateway do
  subject(:gateway) { described_class.new }

  describe "#fetch_assessments_by_date" do
    before do
      ActiveRecord::Base.connection.exec_query("INSERT INTO schemes (scheme_id) VALUES ('9999')")
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessors (scheme_assessor_id, first_name, last_name, date_of_birth, registered_by)
        VALUES ('TEST123456', 'test_forename', 'test_surname', '1970-01-05', 9999)",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry)
        VALUES ('0000-0000-0000-0000-0000', 'TEST123456', 'SAP', '2010-01-04', '2010-01-05', '2010-01-05', '2070-01-05')",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry)
        VALUES ('0000-0000-0000-0000-0001', 'TEST123456', 'SAP', '2010-01-01', '2010-01-01', '2010-01-02', '2070-01-02')",
      )
    end

    it "returns the assessment data for a given day" do
      expect(gateway.fetch_assessments_by_date(date: "2010-01-05")).to match([
        a_hash_including(
          { "assessment_id" => "0000-0000-0000-0000-0000",
            "type_of_assessment" => "SAP",
            "scheme_id" => 9999 },
        ),
      ])
    end

    it "raises an error when an invalid type is provided" do
      expect { gateway.fetch_assessments_by_date(date: "2010-01-05", assessment_types: %w[Non-Existing]) }.to raise_error(StandardError, "Invalid types")
    end

    it "allows to filter by assessment type" do
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry)
        VALUES ('0000-0000-0000-0000-0002', 'TEST123456', 'RdSAP', '2010-01-04', '2010-01-05', '2010-01-05', '2070-01-05')",
      )

      expect(gateway.fetch_assessments_by_date(date: "2010-01-05", assessment_types: %w[SAP])).to match([
        a_hash_including(
          { "assessment_id" => "0000-0000-0000-0000-0000",
            "type_of_assessment" => "SAP",
            "scheme_id" => 9999 },
        ),
      ])
    end

    it "raises an error when an invalid type is provided" do
      expect { gateway.fetch_assessments_by_date("2010-01-05", assessment_types: %w[Non-Existing]) }.to raise_error(StandardError, "Invalid types")
    end

    it "allows to filter by assessment type" do
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry)
        VALUES ('0000-0000-0000-0000-0002', 'TEST123456', 'RdSAP', '2010-01-04', '2010-01-05', '2010-01-05', '2070-01-05')",
      )

      expect(gateway.fetch_assessments_by_date("2010-01-05", assessment_types: %w[SAP])).to match([
        a_hash_including(
          { "assessment_id" => "0000-0000-0000-0000-0000",
            "type_of_assessment" => "SAP",
            "scheme_id" => 9999 },
        ),
      ])
    end
  end
end
