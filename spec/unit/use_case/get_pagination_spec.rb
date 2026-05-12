describe UseCase::GetPagination do
  subject(:use_case) do
    described_class.new(gateway:)
  end

  let(:gateway) do
    instance_double(Gateway::NewReportsGateway)
  end

  let(:start_date) do
    "2023-12-01"
  end

  let(:end_date) do
    "2023-12-23"
  end

  let(:search_arguments) do
    { start_date: start_date, end_date: end_date, current_page: 3, records_per_page: 100 }
  end

  let(:expected_return_hash) do
    { current_page: 3, next_page: 4, previous_page: 2 }
  end

  context "when using the count method" do
    before do
      allow(gateway).to receive(:count).and_return(60_000)
    end

    it "can call the use case" do
      expect { use_case.execute(**search_arguments) }.not_to raise_error
    end

    it "passes the arguments to the gateway to count domestic data" do
      use_case.execute(**search_arguments)
      expect(gateway).to have_received(:count).with(start_date:, end_date:).exactly(1).times
    end

    it "returns the expected hash" do
      expect(use_case.execute(**search_arguments)).to eq expected_return_hash
    end

    context "when there are fewer results than the size of the page" do
      let(:current_page_1_args) do
        { start_date: "2023-12-01", end_date: "2023-12-23", current_page: 1 }
      end

      before do
        allow(gateway).to receive(:count).and_return(20)
      end

      it "returns nil for previous page" do
        expect(use_case.execute(**current_page_1_args)[:previous_page]).to be_nil
      end

      it "returns nil for next page when total records is below threshold" do
        expect(use_case.execute(**current_page_1_args)[:next_page]).to be_nil
      end

      context "when total records is 0" do
        before do
          allow(gateway).to receive_messages(count: 0)
        end

        it "returns nil for previous page" do
          expect(use_case.execute(**current_page_1_args)[:previous_page]).to be_nil
        end

        it "returns nil for next page when total records is below threshold" do
          expect(use_case.execute(**current_page_1_args)[:next_page]).to be_nil
        end
      end

      context "when a url is passed in" do
        let(:search_arguments_with_url) do
          { start_date: "2023-12-01", end_date: "2023-12-23", current_page: 1, url: "example.com/a_param=1&page=1&another_param=2" }
        end

        it "nil for the previous page of results" do
          expect(use_case.execute(**search_arguments_with_url)[:prev]).to be_nil
        end

        it "the url for the current page of results" do
          expect(use_case.execute(**search_arguments_with_url)[:self]).to eq "example.com/a_param=1&page=1&another_param=2"
        end

        it "nil for the next page of results" do
          expect(use_case.execute(**search_arguments_with_url)[:next]).to be_nil
        end
      end
    end

    context "when there are more results than the size of the page" do
      before do
        allow(gateway).to receive_messages(count: 1222)
      end

      let(:search_arguments) do
        { start_date: "2023-12-01", end_date: "2023-12-23", current_page: 2, records_per_page: 100 }
      end

      let(:expected_return_hash) do
        { current_page: 2, next_page: 3, previous_page: 1 }
      end

      it "lets you know what the previous and next page is" do
        result = use_case.execute(**search_arguments)
        expect(result).to eq expected_return_hash
      end

      context "when a url is passed in" do
        before do
          allow(gateway).to receive_messages(count: 1222)
        end

        let(:search_arguments_with_url) do
          { start_date: "2023-12-01", end_date: "2023-12-23", current_page: 2, records_per_page: 100, url: "example.com/a_param=1&page=2&another_param=2" }
        end

        it "returns the url for the previous page of results" do
          expect(use_case.execute(**search_arguments_with_url)[:prev]).to eq "example.com/a_param=1&page=1&another_param=2"
        end

        it "returns the url for the current page of results" do
          expect(use_case.execute(**search_arguments_with_url)[:self]).to eq "example.com/a_param=1&page=2&another_param=2"
        end

        it "returns the url for the next page of results" do
          expect(use_case.execute(**search_arguments_with_url)[:next]).to eq "example.com/a_param=1&page=3&another_param=2"
        end

        context "when the url doesn't contain the current page" do
          # this can happen when requesting the page parameter isn't used so we default to the first page
          let(:search_arguments_with_url) do
            { start_date: "2023-12-01", end_date: "2023-12-23", current_page: 1, records_per_page: 100, url: "example.com/a_param=1&another_param=2" }
          end

          it "returns the url for the current page of results" do
            expect(use_case.execute(**search_arguments_with_url)[:self]).to eq "example.com/a_param=1&another_param=2"
          end

          it "returns nil for the previous page of results" do
            expect(use_case.execute(**search_arguments_with_url)[:prev]).to be_nil
          end

          it "returns the url for the next page of results with the page appended" do
            expect(use_case.execute(**search_arguments_with_url)[:next]).to eq "example.com/a_param=1&another_param=2&page=2"
          end
        end
      end
    end

    context "when current page is out of range" do
      before do
        allow(gateway).to receive_messages(count: 390)
      end

      it "raises an OutOfPaginationRangeError when current page is less than 1" do
        search_args_page_neg1 = { start_date: "2023-12-01", end_date: "2023-12-23", current_page: 0 }
        expect { use_case.execute(**search_args_page_neg1) }.to raise_error(Errors::OutOfPaginationRangeError)
      end

      it "raises an OutOfPaginationRangeError when current page is greater than 1 and there is only one page of results" do
        search_args_page_2 = { start_date: "2023-12-01", end_date: "2023-12-23", current_page: 2 }
        expect { use_case.execute(**search_args_page_2) }.to raise_error(Errors::OutOfPaginationRangeError)
      end
    end
  end

  context "when passed the count scottish events count method" do
    let(:gateway) do
      instance_double(Gateway::AuditLogsGateway)
    end
    let(:event_types) do
      %w[scottish_opt_in]
    end
    let(:search_arguments) do
      { start_date: start_date, end_date: end_date, current_page: 3, records_per_page: 100, count_method: :count_scottish_events, event_types: }
    end

    before do
      allow(gateway).to receive(:count_scottish_events).and_return(60_000)
    end

    it "passes the arguments to the gateway to count domestic data" do
      use_case.execute(**search_arguments)
      expect(gateway).to have_received(:count_scottish_events).with(start_date:, end_date:, event_types:).exactly(1).times
    end

    it "returns the expected hash" do
      expect(use_case.execute(**search_arguments)).to eq expected_return_hash
    end
  end
end
