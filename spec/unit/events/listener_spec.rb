describe Events::Listener do
  subject(:listener) { described_class.new(event_broadcaster) }

  let(:event_broadcaster) { instance_spy(Events::Broadcaster) }

  before do
    listener.attach_listeners
  end

  describe "#attach_listeners" do
    events = %i[
      assessment_lodged
      assessment_address_id_updated
      assessment_opt_out_status_changed
      green_deal_plan_added
      green_deal_plan_updated
      green_deal_plan_deleted
      assessor_added
      match_address_request
    ]

    events.each do |event|
      it "attaches the #{event} event listener" do
        expect(event_broadcaster).to have_received(:on).with(event)
      end
    end

    it "attaches the cancelled events listeners" do
      expect(event_broadcaster).to have_received(:on).with(:assessment_cancelled, :assessment_marked_not_for_issue)
    end
  end

  describe "executing logic for :match_address_request" do
    let(:match_assessment_address_use_case) do
      instance_double(UseCase::MatchAssessmentAddress)
    end

    let(:valid_payload) do
      {
        assessment_id: "0000-0000-0000-0001",
        address_line1: "1 High St",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "London",
        postcode: "SW1A 1AA",
        is_scottish: false,
      }
    end

    let(:valid_scottish_payload) do
      {
        assessment_id: "0000-0000-0000-0002",
        address_line1: "1 Low St",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "Edinburgh",
        postcode: "EH9 3HJ",
        is_scottish: true,
      }
    end

    context "when the address matching during lodgement toggle is on" do
      before do
        Helper::Toggles.set_feature("address-matching-during-lodgement", true)
      end

      after do
        Helper::Toggles.set_feature("address-matching-during-lodgement", false)
      end

      context "when the required arguments are passed" do
        before do
          allow(match_assessment_address_use_case).to receive(:execute)
          allow(ApiFactory).to receive(:match_assessment_address_use_case).and_return(match_assessment_address_use_case)

          allow(event_broadcaster).to receive(:on)
          # rubocop:disable RSpec/Yield. The '.and_yeld' syntax does not work.
          allow(event_broadcaster).to receive(:on).with(:match_address_request) do |&block|
            block.call(**valid_payload)
          end
          # rubocop:enable RSpec/Yield

          listener.attach_listeners
        end

        it "executes the match address use case with mapped arguments" do
          expect(match_assessment_address_use_case).to have_received(:execute).with(
            assessment_id: "0000-0000-0000-0001",
            address_line_1: "1 High St",
            address_line_2: "",
            address_line_3: "",
            address_line_4: "",
            town: "London",
            postcode: "SW1A 1AA",
            is_scottish: false,
          )
        end
      end

      context "when the required arguments are passed for an scottish address" do
        before do
          allow(match_assessment_address_use_case).to receive(:execute)
          allow(ApiFactory).to receive(:match_assessment_address_use_case).and_return(match_assessment_address_use_case)

          allow(event_broadcaster).to receive(:on)
          # rubocop:disable RSpec/Yield. The '.and_yeld' syntax does not work.
          allow(event_broadcaster).to receive(:on).with(:match_address_request) do |&block|
            block.call(**valid_scottish_payload)
          end
          # rubocop:enable RSpec/Yield

          listener.attach_listeners
        end

        it "executes the match address use case with mapped arguments" do
          expect(match_assessment_address_use_case).to have_received(:execute).with(
            assessment_id: "0000-0000-0000-0002",
            address_line_1: "1 Low St",
            address_line_2: "",
            address_line_3: "",
            address_line_4: "",
            town: "Edinburgh",
            postcode: "EH9 3HJ",
            is_scottish: true,
          )
        end
      end

      context "when required arguments are missing" do
        let(:broken_payload) do
          { assessment_id: "123" }
        end

        before do
          allow(event_broadcaster).to receive(:on)
          # rubocop:disable RSpec/Yield. The '.and_yeld' syntax does not work.
          allow(event_broadcaster).to receive(:on).with(:match_address_request) do |&block|
            block.call(**broken_payload)
          end
          # rubocop:enable RSpec/Yield
        end

        it "raises a MissingRequiredParameterError" do
          expect { listener.attach_listeners }.to raise_error(Errors::MissingRequiredParameterError)
        end
      end
    end

    context "when the address matching during lodgement toggle is off" do
      context "when the required arguments are passed" do
        before do
          allow(match_assessment_address_use_case).to receive(:execute)
          allow(ApiFactory).to receive(:match_assessment_address_use_case).and_return(match_assessment_address_use_case)

          allow(event_broadcaster).to receive(:on)
          # rubocop:disable RSpec/Yield. The '.and_yeld' syntax does not work.
          allow(event_broadcaster).to receive(:on).with(:match_address_request) do |&block|
            block.call(**valid_payload)
          end
          # rubocop:enable RSpec/Yield

          listener.attach_listeners
        end

        it "does not execute the match address use case" do
          expect(match_assessment_address_use_case).not_to have_received(:execute)
        end
      end
    end
  end
end
