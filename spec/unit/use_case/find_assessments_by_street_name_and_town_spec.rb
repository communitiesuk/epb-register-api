describe UseCase::FindAssessmentsByStreetNameAndTown do
  subject(:use_case) { described_class.new(gateway) }

  let(:gateway) { instance_double(Gateway::AssessmentsSearchGateway) }

  describe "#execute" do
    let(:results) do
      [Domain::AssessmentSearchResult.new(type_of_assessment: "RdSAP", assessment_id: "0000-0000-0000-0001", address_line1: "1 Some Street", town: "Town", date_of_assessment: "20-12-01", date_of_expiry: "30-12-01", date_registered: "20-12-01", current_energy_efficiency_rating: 76),
       Domain::AssessmentSearchResult.new(type_of_assessment: "RdSAP", assessment_id: "0000-0000-0000-0002", address_line1: "2 Some Street", town: "Town", date_of_assessment: "20-12-01", date_of_expiry: "30-12-01", date_registered: "20-12-01", current_energy_efficiency_rating: 76)]
    end

    before do
      allow(gateway).to receive(:search_by_street_name_and_town).with("Some Street",
                                                                      "Town",
                                                                      %w[RdSAP],
                                                                      limit: 201).and_return(results)
    end

    it "executes the method" do
      use_case.execute("Some Street", "Town", %w[RdSAP])
      expect(gateway).to have_received(:search_by_street_name_and_town)
    end

    it "gets the results" do
      expect(use_case.execute("Some Street", "Town", %w[RdSAP])[:data].length).to eq(2)
    end

    context "when the search has more than 200 results" do
      let(:too_many_results) do
        array = []
        (1..201).each { |_i| array << Domain::AssessmentSearchResult.new(type_of_assessment: "RdSAP", assessment_id: "0000-0000-0000-0001", address_line1: "1 Some Street", town: "Town", date_of_assessment: "20-12-01", date_of_expiry: "30-12-01", date_registered: "20-12-01", current_energy_efficiency_rating: 76) }
        array
      end

      before do
        allow(gateway).to receive(:search_by_street_name_and_town).with("1",
                                                                        "Town",
                                                                        %w[RdSAP],
                                                                        limit: 201).and_return(too_many_results)
      end

      context "when the feature flag is on" do
        before { Helper::Toggles.set_feature("register-api-limit-street-town-results", true) }

        it "raises an error" do
          expect { use_case.execute("1", "Town", %w[RdSAP]) }.to raise_error(Boundary::TooManyResults)
        end
      end

      context "when the feature flag is off" do
        before { Helper::Toggles.set_feature("register-api-limit-street-town-results", false) }

        it "does not raise an error" do
          expect { use_case.execute("1", "Town", %w[RdSAP]) }.not_to raise_error
        end
      end
    end

    context "when the search has 200 results" do
      let(:two_hundred_results) do
        array = []
        id = 1000

        (1..200).each do |i|
          id += 1
          array << Domain::AssessmentSearchResult.new(type_of_assessment: "RdSAP", assessment_id: "0000-0000-0000-#{id}", address_line1: "#{i} Some Street", town: "Town", date_of_assessment: "20-12-01", date_of_expiry: "30-12-01", date_registered: "20-12-01", current_energy_efficiency_rating: 76)
        end
        array
      end

      before do
        allow(gateway).to receive(:search_by_street_name_and_town).with("1",
                                                                        "Town",
                                                                        %w[RdSAP],
                                                                        limit: 201).and_return(two_hundred_results)
      end

      it "does not raise an error" do
        expect { use_case.execute("1", "Town", %w[RdSAP]) }.not_to raise_error
      end

      it "returns the results" do
        expect(use_case.execute("1", "Town", %w[RdSAP])[:data].length).to eq(200)
      end
    end
  end
end
