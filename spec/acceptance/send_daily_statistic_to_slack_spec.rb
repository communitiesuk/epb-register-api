describe "Sending daily statistics to Slack" do
  context "when there are statistics for yesterday" do
    let(:assessment_statistics_gateway) { Gateway::AssessmentStatisticsGateway.new }

    before do
      allow(Worker::SlackNotification).to receive(:perform_async)
      assessment_statistics_gateway.save(assessment_type: "SAP", assessments_count: 82, rating_average: 80, day_date: Date.parse("2022-01-16"), transaction_type: 1, country: "England & Wales")

      assessment_statistics_gateway.save(assessment_type: "SAP", assessments_count: 82, rating_average: 80, day_date: Date.parse("2022-01-17"), transaction_type: 1, country: "England & Wales")
      assessment_statistics_gateway.save(assessment_type: "SAP", assessments_count: 10, rating_average: 40, day_date: Date.parse("2022-01-17"), transaction_type: 1, country: "Northern Ireland")
      assessment_statistics_gateway.save(assessment_type: "RdSAP", assessments_count: 24, rating_average: 28, day_date: Date.parse("2022-01-17"), transaction_type: 4, country: "England & Wales")
      assessment_statistics_gateway.save(assessment_type: "DEC", assessments_count: 5, rating_average: 0, day_date: Date.parse("2022-01-17"), transaction_type: nil, country: "England & Wales")
      assessment_statistics_gateway.save(assessment_type: "AC-CERT", assessments_count: 14, rating_average: 0, day_date: Date.parse("2022-01-17"), transaction_type: nil, country: "England & Wales")
    end

    it "sends aslack notification with yesterdays assessment statistics" do
      Timecop.freeze(2022, 1, 18, 8, 0, 0) do
        UseCase::SendDailyStatsToSlack.new(
          assessment_statistics_gateway: assessment_statistics_gateway,
        ).execute
      end

      message = "The total of *135* assessments were lodged yesterday of which: \n" \
                "• *92* SAPs with an average rating of 60.0\n" \
                "• *24* RdSAPs with an average rating of 28.0\n" \
                "• *5* DECs\n" \
                "• *14* AC-CERTs"
      expect(Worker::SlackNotification).to have_received(:perform_async).with(message)
    end
  end
end
