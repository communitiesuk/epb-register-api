describe "Perform end to end test of exporting and saving assessments as statistic" do
  include RSpecRegisterApiServiceMixin

  context "when there is a certificate saved yesterday" do
    let(:daily_statistics_rake) { get_task("maintenance:daily_statistics") }

    before do
      allow($stdout).to receive(:puts)
      Timecop.freeze(2021, 6, 21, 12, 0, 0) do
        scheme_id = add_scheme_and_get_id
        domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
        add_super_assessor(scheme_id: scheme_id)
        lodge_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )
      end

      Timecop.freeze(2021, 6, 22, 12, 0, 0) do
        daily_statistics_rake.invoke
      end
    end

    it "the rake saves the statistics as a single row" do
      sql = "SELECT assessment_type,assessments_count,rating_average, to_char(day_date, 'YYYY-MM-DD') as day_date  FROM assessment_statistics"

      expect(ActiveRecord::Base.connection.exec_query(sql).first).to match a_hash_including({
        "assessment_type" => "RdSAP",
        "assessments_count" => 1,
        "rating_average" => 50.0,
        "day_date" => "2021-06-21",
      })
    end
  end
end
