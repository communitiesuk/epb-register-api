describe Gateway::AssessorsGateway do
  include RSpecRegisterApiServiceMixin

  let(:assessors_gateway) { described_class.new }

  let(:expected_domestic_assessor) do
    {
      address: {},
      company_details: {},
      contact_details: { email: "person@person.com", telephone_number: "010199991010101" },
      first_name: "Someone",
      last_name: "Person",
      middle_names: "Muddle",
      qualifications: { domestic_rd_sap: "ACTIVE",
                        domestic_sap: "INACTIVE",
                        gda: "INACTIVE",
                        non_domestic_cc4: "INACTIVE",
                        non_domestic_dec: "INACTIVE",
                        non_domestic_nos3: "INACTIVE",
                        non_domestic_nos4: "INACTIVE",
                        non_domestic_nos5: "INACTIVE",
                        non_domestic_sp3: "INACTIVE" },
      registered_by: { name: "test scheme", scheme_id: @scheme_id },
      scheme_assessor_id: "ASSR999999",
      search_results_comparison_postcode: "",
    }
  end

  let(:expected_non_domestic_assessor) do
    {
      address: {},
      company_details: {},
      contact_details: { email: "person@person.com", telephone_number: "010199991010101" },
      first_name: "Someone",
      last_name: "Person",
      middle_names: "Muddle",
      qualifications: { domestic_rd_sap: "INACTIVE",
                        domestic_sap: "INACTIVE",
                        gda: "INACTIVE",
                        non_domestic_cc4: "INACTIVE",
                        non_domestic_dec: "INACTIVE",
                        non_domestic_nos3: "ACTIVE",
                        non_domestic_nos4: "ACTIVE",
                        non_domestic_nos5: "ACTIVE",
                        non_domestic_sp3: "INACTIVE" },
      registered_by: { name: "test scheme", scheme_id: @scheme_id },
      scheme_assessor_id: "ASSR000000",
      search_results_comparison_postcode: "",
    }
  end

  let(:expected_gdp_assessor) do
    {
      address: {},
      company_details: {},
      contact_details: { email: "person@person.com", telephone_number: "010199991010101" },
      first_name: "Someone",
      last_name: "Person",
      middle_names: "Muddle",
      qualifications: { domestic_rd_sap: "INACTIVE",
                        domestic_sap: "INACTIVE",
                        gda: "ACTIVE",
                        non_domestic_cc4: "INACTIVE",
                        non_domestic_dec: "INACTIVE",
                        non_domestic_nos3: "INACTIVE",
                        non_domestic_nos4: "INACTIVE",
                        non_domestic_nos5: "INACTIVE",
                        non_domestic_sp3: "INACTIVE" },
      registered_by: { name: "test scheme", scheme_id: @scheme_id },
      scheme_assessor_id: "ASSR888888",
      search_results_comparison_postcode: "",
    }
  end

  describe ".search_by" do
    before(:all) do
      @scheme_id = add_scheme_and_get_id
      add_assessor(
        @scheme_id,
        "ASSR999999",
        AssessorStub.new.fetch_request_body(
          domesticRdSap: "ACTIVE",
          domesticSap: "INACTIVE",
          nonDomesticNos3: "INACTIVE",
          nonDomesticNos4: "INACTIVE",
          nonDomesticNos5: "INACTIVE",
          nonDomesticDec: "INACTIVE",
          nonDomesticSp3: "INACTIVE",
          nonDomesticCc4: "INACTIVE",
          gda: "INACTIVE",
        ),
      )
      add_assessor(
        @scheme_id,
        "ASSR000000",
        AssessorStub.new.fetch_request_body(
          domesticRdSap: "INACTIVE",
          domesticSap: "INACTIVE",
          nonDomesticNos3: "ACTIVE",
          nonDomesticNos4: "ACTIVE",
          nonDomesticNos5: "ACTIVE",
          nonDomesticDec: "INACTIVE",
          nonDomesticSp3: "INACTIVE",
          nonDomesticCc4: "INACTIVE",
          gda: "INACTIVE",
        ),
      )
    end

    context "when searching for assessors with specific qualifications" do
      it "returns the assessor with at least one active domestic qualification" do
        expect { assessors_gateway.search_by(name: "Someone Person", qualification_type: "something_made_up") }.to raise_error(ArgumentError, "The type of qualification must be either 'domestic' or 'nonDomestic'")
      end

      it "returns the assessor with at least one active domestic qualification" do
        result = assessors_gateway.search_by(name: "Someone Person", qualification_type: "domestic")

        expect(result.count).to eq(1)
        expect(result).to eq([expected_domestic_assessor])
      end

      it "returns the assessor with at least one active non-domestic qualification" do
        result = assessors_gateway.search_by(name: "Someone Person", qualification_type: "nonDomestic")

        expect(result.count).to eq(1)
        expect(result).to eq([expected_non_domestic_assessor])
      end

      it "returns assessors with only active green deal plan qualifications in both searches" do
        add_assessor(
          @scheme_id,
          "ASSR888888",
          AssessorStub.new.fetch_request_body(
            domesticRdSap: "INACTIVE",
            domesticSap: "INACTIVE",
            nonDomesticNos3: "INACTIVE",
            nonDomesticNos4: "INACTIVE",
            nonDomesticNos5: "INACTIVE",
            nonDomesticDec: "INACTIVE",
            nonDomesticSp3: "INACTIVE",
            nonDomesticCc4: "INACTIVE",
            gda: "ACTIVE",
          ),
        )
        domestic_search_result = assessors_gateway.search_by(name: "Someone Person", qualification_type: "domestic")
        non_domestic_search_result = assessors_gateway.search_by(name: "Someone Person", qualification_type: "nonDomestic")

        expect(domestic_search_result).to match_array([expected_domestic_assessor, expected_gdp_assessor])
        expect(non_domestic_search_result).to match_array([expected_non_domestic_assessor, expected_gdp_assessor])
      end
    end
  end
end
