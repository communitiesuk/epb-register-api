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
  let(:assessor_domain) do
    Domain::Assessor.new(
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
      address_line1:
        "Flat 33",
      address_line2: "18 Palmtree Road",
      address_line3: "",
      town: "Brighton",
      postcode: "SE1 7EZ",
      company_reg_no: "23222",
      company_address_line1: "1 Company Building",
      company_address_line2: "Company Street",
      company_address_line3: "Oraganisation district",
      company_town: "Monoploy",
      company_postcode: "NE53 2WS",
      company_website: "companny@test.uk",
      company_telephone_number: "00000002000",
      company_email: "emailme@company.org",
      company_name: "My Company",
      domestic_sap_qualification: "ACTIVE",
      domestic_rd_sap_qualification: "ACTIVE",
      non_domestic_sp3_qualification: "ACTIVE",
      non_domestic_cc4_qualification: "ACTIVE",
      non_domestic_dec_qualification: "ACTIVE",
      non_domestic_nos3_qualification: "ACTIVE",
      non_domestic_nos4_qualification: "ACTIVE",
      non_domestic_nos5_qualification: "ACTIVE",
      gda_qualification: "ACTIVE",
      scotland_dec_and_ar_qualification: "INACTIVE",
      scotland_nondomestic_existing_building_qualification: "INACTIVE",
      scotland_nondomestic_new_building_qualification: "INACTIVE",
      scotland_rdsap_qualification: "INACTIVE",
      scotland_sap_existing_building_qualification: "INACTIVE",
      scotland_sap_new_building_qualification: "INACTIVE",
      scotland_section63_qualification: "INACTIVE",
    )
  end
  let(:assessor_domain_active) do
    Domain::Assessor.new(
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
      address_line1:
        "Flat 33",
      address_line2: "18 Palmtree Road",
      address_line3: "",
      town: "Brighton",
      postcode: "SE1 7EZ",
      company_reg_no: "23222",
      company_address_line1: "1 Company Building",
      company_address_line2: "Company Street",
      company_address_line3: "Oraganisation district",
      company_town: "Monoploy",
      company_postcode: "NE53 2WS",
      company_website: "companny@test.uk",
      company_telephone_number: "00000002000",
      company_email: "emailme@company.org",
      company_name: "My Company",
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
    )
  end
  let(:assessor_domain_inactive) do
    Domain::Assessor.new(
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
      address_line1:
        "Flat 33",
      address_line2: "18 Palmtree Road",
      address_line3: "",
      town: "Brighton",
      postcode: "SE1 7EZ",
      company_reg_no: "23222",
      company_address_line1: "1 Company Building",
      company_address_line2: "Company Street",
      company_address_line3: "Oraganisation district",
      company_town: "Monoploy",
      company_postcode: "NE53 2WS",
      company_website: "companny@test.uk",
      company_telephone_number: "00000002000",
      company_email: "emailme@company.org",
      company_name: "My Company",
      domestic_sap_qualification: "INACTIVE",
    )
  end
  let(:auth_client_id) { "SCHE423444" }
  let(:assessor_details) do
    {
      first_name: "Test",
      middle_names: "Brian",
      last_name: "Assessor",
      date_of_birth: "2000-10-01",
      contact_details: {
        telephone_number: "07865672531",
        email: "test@example.com",
      },
      search_results_comparison_postcode: "SE32 5TR",
      also_known_as: "Bob",
      address: {
        address_line1:
          "Flat 33",
        address_line2: "18 Palmtree Road",
        address_line3: "",
        town: "Brighton",
        postcode: "SE1 7EZ",
      },
      company_details: {
        company_reg_no: "23222",
        company_address_line1: "1 Company Building",
        company_address_line2: "Company Street",
        company_address_line3: "Oraganisation district",
        company_town: "Monoploy",
        company_postcode: "NE53 2WS",
        company_website: "companny@test.uk",
        company_telephone_number: "00000002000",
        company_email: "emailme@company.org",
        company_name: "My Company",
      },
      qualifications: {
        domestic_sap: "ACTIVE",
        domestic_rd_sap: "ACTIVE",
        non_domestic_sp3: "ACTIVE",
        non_domestic_cc4: "ACTIVE",
        non_domestic_dec: "ACTIVE",
        non_domestic_nos3: "ACTIVE",
        non_domestic_nos4: "ACTIVE",
        non_domestic_nos5: "ACTIVE",
        gda: "ACTIVE",
        scotland_rdsap: "ACTIVE",
        scotland_sap_existing_building: "ACTIVE",
        scotland_sap_new_building: "ACTIVE",
        scotland_dec_and_ar: "ACTIVE",
        scotland_nondomestic_existing_building: "ACTIVE",
        scotland_nondomestic_new_building: "ACTIVE",
        scotland_section63: "ACTIVE",
      },
    }
  end
  let(:assessor_details_without_qualifications) do
    new_details = assessor_details.dup.reject { |key, _| key == :qualifications }
    new_details[:contact_details][:telephone_number] = "07111111111"
    new_details
  end
  let(:assessor_details_update_non_scottish_qualifications) do
    new_details = assessor_details.dup
    new_details[:qualifications].each_key do |key|
      new_details[:qualifications][key] = "INACTIVE" unless key.to_s.start_with?("scotland_")
    end
    new_details
  end
  let(:assessor_details_without_scottish_qualifications) do
    new_details = assessor_details.dup
    new_details[:qualifications].reject! { |key, _| key.to_s.start_with?("scotland_") }
    new_details
  end

  # context "when an assessor id is malformed" do
  #   it "raises an exception for an invalid assessor ID" do
  #     bad_assessor_id = "this_is_bad"
  #     add_assessor_request =
  #       Boundary::AssessorRequest.new(
  #         body: assessor_details,
  #         scheme_assessor_id: bad_assessor_id,
  #         registered_by_id: 1,
  #       )
  #     expect {
  #       use_case.execute(add_assessor_request, "fake_token")
  #     }.to raise_error UseCase::AddAssessor::InvalidAssessorIdException,
  #                      /#{Regexp.quote(bad_assessor_id)}/
  #   end
  # end

  context "when a scheme is not in the database" do
    before do
      allow(schemes_gateway_double).to receive(:all).and_return([{}])
    end

    it "raises an exception for scheme not found" do
      add_assessor_request =
        Boundary::AssessorRequest.new(
          body: assessor_details,
          scheme_assessor_id: "SCHE423444",
          registered_by_id: 1,
        )
      expect {
        use_case.execute(add_assessor_request, auth_client_id)
      }.to raise_error UseCase::AddAssessor::SchemeNotFoundException
    end
  end

  context "when adding an assessor" do
    before do
      allow(assessors_gateway_double).to receive_messages(fetch: nil, update: true)
      allow(events_broadcaster_double).to receive(:broadcast).and_return(true)
    end

    context "when a new assessor is added successfully" do
      before do
        allow(schemes_gateway_double).to receive(:all).and_return([{ scheme_id: 1, name: "test scheme", active: true, active_scotland: true, active_eng_wls_nir: true }])
        add_assessor_request =
          Boundary::AssessorRequest.new(
            body: assessor_details,
            scheme_assessor_id: "SCHE423444",
            registered_by_id: 1,
          )
        use_case.execute(add_assessor_request, auth_client_id)
      end

      it "calls the assessors gateway" do
        expect(assessors_gateway_double).to have_received(:fetch)
        expect(assessors_gateway_double).to have_received(:update)
      end

      it "broadcasts this message" do
        expect(events_broadcaster_double).to have_received(:broadcast).once
      end
    end

    context "when a scheme attempts to add an assessor with qualifications outside of their active region (non-scotland)" do
      before do
        allow(schemes_gateway_double).to receive(:all).and_return([{ scheme_id: 1, name: "test scheme", active: true, active_scotland: false, active_eng_wls_nir: true }])
      end

      it "raises an SchemeCannotLodgeInRegion error" do
        add_assessor_request =
          Boundary::AssessorRequest.new(
            body: assessor_details,
            scheme_assessor_id: "SCHE423444",
            registered_by_id: 1,
          )
        expect { use_case.execute(add_assessor_request, auth_client_id) }.to raise_error UseCase::AddAssessor::SchemeCannotLodgeInRegion
      end

      context "when the toggle is off" do
        before do
          Helper::Toggles.set_feature("register-api-add-check-on-schemes-active-regions", false)
        end

        after do
          Helper::Toggles.set_feature("register-api-add-check-on-schemes-active-regions", true)
        end

        it "is able to add the assessor" do
          add_assessor_request =
            Boundary::AssessorRequest.new(
              body: assessor_details,
              scheme_assessor_id: "SCHE423444",
              registered_by_id: 1,
            )
          expect { use_case.execute(add_assessor_request, auth_client_id) }.not_to raise_error
        end
      end
    end

    context "when a scheme attempts to add an assessor with qualifications outside of their active region (scotland)" do
      before do
        allow(schemes_gateway_double).to receive(:all).and_return([{ scheme_id: 1, name: "test scheme", active: false, active_scotland: true, active_eng_wls_nir: false }])
      end

      it "raises an SchemeCannotLodgeInRegion error" do
        add_assessor_request =
          Boundary::AssessorRequest.new(
            body: assessor_details_update_non_scottish_qualifications,
            scheme_assessor_id: "SCHE423444",
            registered_by_id: 1,
          )
        expect { use_case.execute(add_assessor_request, auth_client_id) }.to raise_error UseCase::AddAssessor::SchemeCannotLodgeInRegion
      end

      context "when the toggle is off" do
        before do
          Helper::Toggles.set_feature("register-api-add-check-on-schemes-active-regions", false)
        end

        after do
          Helper::Toggles.set_feature("register-api-add-check-on-schemes-active-regions", true)
        end

        it "is able to add the assessor" do
          add_assessor_request =
            Boundary::AssessorRequest.new(
              body: assessor_details_update_non_scottish_qualifications,
              scheme_assessor_id: "SCHE423444",
              registered_by_id: 1,
            )
          expect { use_case.execute(add_assessor_request, auth_client_id) }.not_to raise_error
        end
      end
    end
  end

  context "when updating an assessor" do
    before do
      allow(schemes_gateway_double).to receive(:all).and_return([{ scheme_id: 1, name: "test scheme", active: true, active_scotland: true, active_eng_wls_nir: true }])
      allow(assessors_gateway_double).to receive_messages(fetch: assessor_domain, update: true)
      allow(assessor_status_events_gateway_double).to receive(:add).and_return(true)
      allow(events_broadcaster_double).to receive(:broadcast)
    end

    context "when an assessor is updated successfully" do
      before do
        add_assessor_request =
          Boundary::AssessorRequest.new(
            body: assessor_details,
            scheme_assessor_id: "SCHE423444",
            registered_by_id: 1,
          )
        use_case.execute(add_assessor_request, auth_client_id)
      end

      it "calls the assessors gateway" do
        expect(assessors_gateway_double).to have_received(:fetch).once
        expect(assessors_gateway_double).to have_received(:update).once
      end

      it "calls the assessors_status_events_gateway for each updated qualification type" do
        expect(assessor_status_events_gateway_double).to have_received(:add).exactly(7).times
      end

      it "does not broadcasts this message" do
        expect(events_broadcaster_double).not_to have_received(:broadcast)
      end
    end

    context "when a scheme tries to update an assessor belonging to a different scheme" do
      before do
        allow(schemes_gateway_double).to receive(:all).and_return([{ scheme_id: 2, name: "test scheme", active: true, active_scotland: true, active_eng_wls_nir: true }])
        allow(assessors_gateway_double).to receive(:fetch).and_return(assessor_domain)
      end

      it "raises an exception for assessor registered by another scheme" do
        add_assessor_request =
          Boundary::AssessorRequest.new(
            body: assessor_details,
            scheme_assessor_id: "SCHE222444",
            registered_by_id: 2,
          )
        expect {
          use_case.execute(add_assessor_request, auth_client_id)
        }.to raise_error UseCase::AddAssessor::AssessorRegisteredOnAnotherScheme
      end
    end

    # Need to possibly fix this behaviour
    context "when a scheme does not include the qualifications" do
      context "when the existing qualifications are set to inactive" do
        before do
          allow(assessors_gateway_double).to receive_messages(fetch: assessor_domain_inactive, update: true)
        end

        it "does not call the assessors_status_events_gateway" do
          add_assessor_request =
            Boundary::AssessorRequest.new(
              body: assessor_details_without_qualifications,
              scheme_assessor_id: "SCHE423444",
              registered_by_id: 1,
            )
          use_case.execute(add_assessor_request, auth_client_id)
          expect(assessor_status_events_gateway_double).not_to have_received(:add)
        end
      end

      context "when the existing qualifications are not set to inactive" do
        before do
          allow(assessors_gateway_double).to receive_messages(fetch: assessor_domain_active, update: true)
        end

        it "does call the assessors_status_events_gateway as the qualifications get set to nil" do
          add_assessor_request =
            Boundary::AssessorRequest.new(
              body: assessor_details_without_qualifications,
              scheme_assessor_id: "SCHE423444",
              registered_by_id: 1,
            )
          use_case.execute(add_assessor_request, auth_client_id)
          expect(assessor_status_events_gateway_double).to have_received(:add).exactly(16).times
        end
      end
    end

    context "when a scheme attempts to update an assessors qualification but is no longer active in that region" do
      before do
        allow(schemes_gateway_double).to receive(:all).and_return([{ scheme_id: 1, name: "test scheme", active: true, active_scotland: false, active_eng_wls_nir: true }])
        allow(assessors_gateway_double).to receive_messages(fetch: assessor_domain_active, update: true)
      end

      it "raises an exception when the scottish qualifications are in the request" do
        add_assessor_request =
          Boundary::AssessorRequest.new(
            body: assessor_details,
            scheme_assessor_id: "SCHE423444",
            registered_by_id: 1,
          )

        expect { use_case.execute(add_assessor_request, auth_client_id) }.to raise_error UseCase::AddAssessor::SchemeCannotLodgeInRegion
      end

      it "update the scottish qualifications to nil when the scottish qualifications are absent" do
        add_assessor_request =
          Boundary::AssessorRequest.new(
            body: assessor_details_without_scottish_qualifications,
            scheme_assessor_id: "SCHE423444",
            registered_by_id: 1,
          )
        expect { use_case.execute(add_assessor_request, auth_client_id) }.not_to raise_error
        expect(assessor_status_events_gateway_double).to have_received(:add).exactly(7).times
      end
    end
  end
end
