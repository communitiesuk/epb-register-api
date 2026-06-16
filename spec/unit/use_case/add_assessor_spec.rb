describe UseCase::AddAssessor do
  subject(:use_case) do
    described_class.new(
      schemes_gateway: schemes_gateway_double,
      assessors_gateway: assessors_gateway_double,
      assessors_status_events_gateway: assessor_status_events_gateway_double,
      event_broadcaster: events_broadcaster_double,
    )
  end

  let(:schemes_gateway_double) { instance_double(Gateway::SchemesGateway) }
  let(:assessors_gateway_double) { instance_double(Gateway::AssessorsGateway) }
  let(:assessor_status_events_gateway_double) { instance_double(Gateway::AssessorsStatusEventsGateway) }
  let(:events_broadcaster_double) { instance_double(Events::Broadcaster) }

  context "when an assessor id is malformed" do
    it "raises an exception for an invalid assessor ID" do
      bad_assessor_id = "this_is_bad"
      add_assessor_request =
        Boundary::AssessorRequest.new(
          body: {},
          scheme_assessor_id: bad_assessor_id,
          registered_by_id: 1,
        )
      expect {
        use_case.execute(add_assessor_request, "fake_token")
      }.to raise_error UseCase::AddAssessor::InvalidAssessorIdException,
                       /#{Regexp.quote(bad_assessor_id)}/
    end
  end

  context "when a scheme is not in the database" do
    before do
      allow(schemes_gateway_double).to receive(:all).and_return([{}])
    end

    it "raises an exception for scheme not found" do
      add_assessor_request =
        Boundary::AssessorRequest.new(
          body: {},
          scheme_assessor_id: "SCHE423444",
          registered_by_id: 1,
        )
      expect {
        use_case.execute(add_assessor_request, "SCHE423444")
      }.to raise_error UseCase::AddAssessor::SchemeNotFoundException
    end
  end

  context "when an assessor is added successfully" do
    before do
      allow(schemes_gateway_double).to receive(:all).and_return([{ scheme_id: 1, name: "test scheme", active: true, active_scotland: true, active_eng_wls_nir: true }])
      allow(assessors_gateway_double).to receive_messages(fetch: nil, update: true)
      allow(events_broadcaster_double).to receive(:broadcast).and_return(true)
    end

    it "does not raise an error" do
      add_assessor_request =
        Boundary::AssessorRequest.new(
          body: {},
          scheme_assessor_id: "SCHE423444",
          registered_by_id: 1,
        )
      expect {
        use_case.execute(add_assessor_request, "SCHE423444")
      }.not_to raise_error
    end
  end

  context "when an assessor is updated successfully" do
    before do
      allow(schemes_gateway_double).to receive(:all).and_return([{ scheme_id: 1, name: "test scheme", active: true, active_scotland: true, active_eng_wls_nir: true }])
      allow(assessors_gateway_double).to receive_messages(fetch: Domain::Assessor.new(
        scheme_assessor_id: "SCHE423444",
        first_name: "Test",
        last_name: "Assessor",
        middle_names: "Brian",
        date_of_birth: "2000-10-01",
        email: "test@example.com",
        telephone_number: "07865672531",
        registered_by_id: 1,
        registered_by_name: "test scheme",
        search_results_comparison_postcode:
          "SE32 5TR",
        also_known_as: "Bob",
        address_line1: "6 Street place",
        address_line2: "Whimple area",
        address_line3: "Bloopshire",
        town: "London",
        postcode: "we 32 4ew",
        company_reg_no: "23222",
        company_address_line1: "3 Week street",
        company_address_line2: "Bloop place",
        company_address_line3: "London",
        company_town: "London",
        company_postcode: "AA1 2AA",
        company_website: "test.com",
        company_telephone_number: "07865672531",
        company_email: "test@example.com",
        company_name: "Test",
        domestic_sap_qualification: "ACTIVE",
        domestic_rd_sap_qualification: "ACTIVE",
        non_domestic_sp3_qualification: "ACTIVE",
        non_domestic_cc4_qualification: "ACTIVE",
        non_domestic_dec_qualification: "ACTIVE",
        non_domestic_nos3_qualification: "ACTIVE",
        non_domestic_nos4_qualification: "ACTIVE",
        non_domestic_nos5_qualification: "ACTIVE",
        gda_qualification: "ACTIVE",
        scotland_dec_and_ar_qualification: "ACTIVE",
        scotland_nondomestic_existing_building_qualification: "ACTIVE",
        scotland_nondomestic_new_building_qualification: "ACTIVE",
        scotland_rdsap_qualification: "ACTIVE",
        scotland_sap_existing_building_qualification: "ACTIVE",
        scotland_sap_new_building_qualification: "ACTIVE",
        scotland_section63_qualification: "ACTIVE",
      ), update: true)
      allow(assessor_status_events_gateway_double).to receive(:add).and_return(true)
    end

    it "does not raise an error" do
      add_assessor_request =
        Boundary::AssessorRequest.new(
          body: {},
          scheme_assessor_id: "SCHE423444",
          registered_by_id: 1,
        )
      expect {
        use_case.execute(add_assessor_request, "SCHE423444")
      }.not_to raise_error
    end
  end

  context "when a scheme tries to update an assessor belonging to a different scheme" do
    before do
      allow(schemes_gateway_double).to receive(:all).and_return([{ scheme_id: 1, name: "test scheme", active: true, active_scotland: true, active_eng_wls_nir: true }])
      allow(assessors_gateway_double).to receive(:fetch).and_return(Domain::Assessor.new(
                                                                      scheme_assessor_id: "SCHE423444",
                                                                      first_name: "Test",
                                                                      last_name: "Assessor",
                                                                      middle_names: "Brian",
                                                                      date_of_birth: "2000-10-01",
                                                                      email: "test@example.com",
                                                                      telephone_number: "07865672531",
                                                                      registered_by_id: 2,
                                                                      registered_by_name: "other scheme",
                                                                      search_results_comparison_postcode:
                                                                        "SE32 5TR",
                                                                      also_known_as: "Bob",
                                                                      address_line1: "6 Street place",
                                                                      address_line2: "Whimple area",
                                                                      address_line3: "Bloopshire",
                                                                      town: "London",
                                                                      postcode: "we 32 4ew",
                                                                      company_reg_no: "23222",
                                                                      company_address_line1: "3 Week street",
                                                                      company_address_line2: "Bloop place",
                                                                      company_address_line3: "London",
                                                                      company_town: "London",
                                                                      company_postcode: "AA1 2AA",
                                                                      company_website: "test.com",
                                                                      company_telephone_number: "07865672531",
                                                                      company_email: "test@example.com",
                                                                      company_name: "Test",
                                                                      domestic_sap_qualification: "ACTIVE",
                                                                      domestic_rd_sap_qualification: "ACTIVE",
                                                                      non_domestic_sp3_qualification: "ACTIVE",
                                                                      non_domestic_cc4_qualification: "ACTIVE",
                                                                      non_domestic_dec_qualification: "ACTIVE",
                                                                      non_domestic_nos3_qualification: "ACTIVE",
                                                                      non_domestic_nos4_qualification: "ACTIVE",
                                                                      non_domestic_nos5_qualification: "ACTIVE",
                                                                      gda_qualification: "ACTIVE",
                                                                      scotland_dec_and_ar_qualification: "ACTIVE",
                                                                      scotland_nondomestic_existing_building_qualification: "ACTIVE",
                                                                      scotland_nondomestic_new_building_qualification: "ACTIVE",
                                                                      scotland_rdsap_qualification: "ACTIVE",
                                                                      scotland_sap_existing_building_qualification: "ACTIVE",
                                                                      scotland_sap_new_building_qualification: "ACTIVE",
                                                                      scotland_section63_qualification: "ACTIVE",
                                                                    ))
    end

    it "raises an exception for assessor registered by another scheme" do
      add_assessor_request =
        Boundary::AssessorRequest.new(
          body: {},
          scheme_assessor_id: "SCHE423444",
          registered_by_id: 1,
        )
      expect {
        use_case.execute(add_assessor_request, "SCHE423444")
      }.to raise_error UseCase::AddAssessor::AssessorRegisteredOnAnotherScheme
    end
  end
end
