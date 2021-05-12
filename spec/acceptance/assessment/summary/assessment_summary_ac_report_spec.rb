describe "Acceptance::AssessmentSummary::AC-REPORT", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  context "when requesting summary of a lodged AC-REPORT" do
    let(:scheme_id) { add_scheme_and_get_id }

    before do
      add_assessor(
        scheme_id,
        "SPEC000000",
        AssessorStub.new.fetch_request_body(
          nonDomesticSp3: "ACTIVE",
          nonDomesticCc4: "ACTIVE",
        ),
      )
    end

    %w[
      CEPC-NI-8.0.0
      CEPC-8.0.0
      CEPC-7.1
      CEPC-7.0
      CEPC-6.0
      CEPC-5.1
      CEPC-5.0
      CEPC-4.0
    ].each do |schema_name|
      context "when the report was lodged with schema #{schema_name}" do
        before { lodge_test_ac_report(scheme_id, schema_name) }

        let(:summary) do
          JSON.parse(
            fetch_assessment_summary("0000-0000-0000-0000-0000").body,
            symbolize_names: true,
          )
        end

        it "does not return blank recommendation entries" do
          management_recommendations =
            summary[:data][:keyRecommendations][:management]

          empty_recommendations =
            management_recommendations.filter do |r|
              r[:text].nil? || r[:text].empty?
            end
          expect(empty_recommendations).to be_empty

          filled_recommendations =
            management_recommendations.reject do |r|
              r[:text].nil? || r[:text].empty?
            end
          expect(filled_recommendations).not_to be_empty
        end
      end
    end
  end
end

def lodge_test_ac_report(scheme_id, schema_name, xml = nil)
  xml = Samples.xml(schema_name, "ac-report") if xml.nil?

  lodge_assessment(
    assessment_body: xml,
    auth_data: {
      scheme_ids: [scheme_id],
    },
    schema_name: schema_name,
  )
end
