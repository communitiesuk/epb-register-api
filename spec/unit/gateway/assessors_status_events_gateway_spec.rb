describe Gateway::AssessorsStatusEventsGateway, :set_with_timecop do
  include RSpecRegisterApiServiceMixin
  subject(:gateway) { described_class.new }

  before do
    scheme_id = add_scheme_and_get_id

    # create new assessor
    add_assessor(
      scheme_id:,
      assessor_id: "ACME123456",
      body: AssessorStub.new.fetch_request_body,
    )

    # change that assessors scottish qualification from inactive to active to generate an event
    add_assessor(
      scheme_id:,
      assessor_id: "ACME123456",
      body: AssessorStub.new.fetch_request_body(scotland_rdsap: "ACTIVE"),
    )

    # change that assessors non-scottish qualification from inactive to active to generate an event
    add_assessor(
      scheme_id:,
      assessor_id: "ACME123456",
      body: AssessorStub.new.fetch_request_body(scotland_rdsap: "ACTIVE", domestic_rd_sap: "ACTIVE"),
    )

    # change that assessors scottish qualification from active to struckoff to generate an event
    add_assessor(
      scheme_id:,
      assessor_id: "ACME123456",
      body: AssessorStub.new.fetch_request_body(scotland_rdsap: "STRUCKOFF", domestic_rd_sap: "ACTIVE"),
    )

    # change that assessors scottish qualification from struckoff to suspended to generate an event
    add_assessor(
      scheme_id:,
      assessor_id: "ACME123456",
      body: AssessorStub.new.fetch_request_body(scotland_rdsap: "SUSPENDED", domestic_rd_sap: "ACTIVE"),
    )
  end

  describe "#get_scottish_assessor_events" do
    context "when there are five events in the audit log between two dates" do
      it "returns only the changes to a scottish qualification" do
        result = gateway.get_scottish_assessor_events(start_date: Time.now - 10.days, end_date: Time.now, current_page: 1)
        expect(result.length).to eq(3)
        expect(result.first[:qualification_change]).to eq({ new_status: "ACTIVE",
                                                            previous_status: "INACTIVE",
                                                            qualification_type: "scotland_rdsap" })
      end

      it "only returns events between the two dates" do
        result = gateway.get_scottish_assessor_events(start_date: Time.now - 10.days, end_date: Time.now - 8.days, current_page: 1)
        expect(result.length).to eq(0)
      end

      context "when there are more results than the limit" do
        it "returns an array the size of the limit when you request the first page" do
          result = gateway.get_scottish_assessor_events(start_date: Time.now - 10.days, end_date: Time.now, current_page: 1, limit: 2)
          expect(result.length).to eq(2)
        end

        it "returns the remaining records on the second page" do
          result = gateway.get_scottish_assessor_events(start_date: Time.now - 10.days, end_date: Time.now, current_page: 2, limit: 2)
          expect(result.length).to eq(1)
        end
      end
    end
  end

  describe "#count_scottish_assessor_events" do
    it "returns a count of events between the two dates" do
      result = gateway.count_scottish_assessor_events(start_date: Time.now - 10.days, end_date: Time.now)
      expect(result).to eq 3
    end
  end
end
