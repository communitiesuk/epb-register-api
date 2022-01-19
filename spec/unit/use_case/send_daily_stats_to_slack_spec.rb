describe UseCase::SendDailyStatsToSlack do
  describe "#execute" do
    subject(:use_case) { described_class.new(assessment_statistics_gateway: assessment_statistics_gateway) }

    let(:assessment_statistics_gateway) { instance_double(Gateway::AssessmentStatisticsGateway) }

    before(:all) { Timecop.freeze(2022, 1, 18, 0, 0, 0) }

    after(:all) { Timecop.return }

    context "when there are no statistics for yesterday" do
      before do
        allow(Worker::SlackNotification).to receive(:perform_async)
        allow(assessment_statistics_gateway).to receive(:fetch_daily_stats_by_date).with("2022-01-17").and_return([])
      end

      it "calls the worker with correct message" do
        use_case.execute

        no_stats_message = "No stats for yesterday. Assessors were on hols :palm_tree: or our scheduled job didn't work :robot_face:"
        expect(Worker::SlackNotification).to have_received(:perform_async).with(no_stats_message)
      end
    end

    context "when there are statistics for yesterday" do
      let(:stats_data) do
        [{ "assessment_type" => "SAP", "number_of_assessments" => 92, "rating_average" => 60.0 },
         { "assessment_type" => "RdSAP", "number_of_assessments" => 24, "rating_average" => 28.0 },
         { "assessment_type" => "DEC", "number_of_assessments" => 5, "rating_average" => 0.0 },
         { "assessment_type" => "AC-CERT", "number_of_assessments" => 14, "rating_average" => 0.0 }]
      end

      before do
        allow(Worker::SlackNotification).to receive(:perform_async)
        allow(assessment_statistics_gateway).to receive(:fetch_daily_stats_by_date).with("2022-01-17").and_return(stats_data)
      end

      it "calls the worker with correct message" do
        use_case.execute

        message = "The total of *135* assessments were lodged yesterday of which: \n" \
                  "  *92* SAPs with an average rating of 60.0\n" \
                  "  *24* RdSAPs with an average rating of 28.0\n" \
                  "  *5* DECs\n" \
                  "  *14* AC-CERTs"
        expect(Worker::SlackNotification).to have_received(:perform_async).with(message)
      end
    end
  end
end
