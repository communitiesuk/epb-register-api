describe UseCase::ExportOpenDataCommercial do
  include RSpecRegisterApiServiceMixin

  require_relative "../cepc_view_model_test_helper"

  context "when creating the open data reporting release" do
    describe "for the commercial certificates and reports" do

      before(:example) do
       scheme_id = add_scheme_and_get_id
       non_domestic_xml=  Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
       non_domestic_assessment_id = non_domestic_xml.at("//CEPC:RRN")
       non_domestic_assessment_date=  non_domestic_xml.at("//CEPC:Registration-Date")

        add_assessor(
          scheme_id,
          "SPEC000000",
          AssessorStub.new.fetch_request_body(
            nonDomesticNos3: "ACTIVE",
            nonDomesticNos4: "ACTIVE",
            nonDomesticNos5: "ACTIVE",
            nonDomesticDec: "ACTIVE",
            domesticRdSap: "ACTIVE",
            domesticSap: "ACTIVE",
            nonDomesticSp3: "ACTIVE",
            nonDomesticCc4: "ACTIVE",
            gda: "ACTIVE",
            ),
          )

        non_domestic_assessment_date.children = "2020-05-04"
        lodged = lodge_assessment(
          assessment_body: non_domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          override: true,
            schema_name: "CEPC-8.0.0",
          )


        non_domestic_assessment_date.children = "2018-05-04"
        non_domestic_assessment_id.children = "0000-0000-0000-0000-0001"
        lodge_assessment(
          assessment_body: non_domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          override: true,
            schema_name: "CEPC-8.0.0",
          )

        open_data_export = described_class.new
        @data = open_data_export.execute(
          { number_of_assessments: @number_assments_to_test, max_runs: "3", batch: "3" },
          )
      end
      # test data does not need to be set for every assertion
      expected_values = hash_to_test()
      #
      # number_assments_to_test = 2

      it "returns the correct nubmer of assesments in the CSV" do
        expect(@data.length).to eq(2)
      end

      # 1st row to test
      keys_to_test = hash_to_test
      # write at test for each key in test hash
      hash_to_test.keys.each{|index|
        expected = update_test_hash({rrn: "0000-0000-0000-0000-0001", lodgement_date: "2018-05-04", })
        it "returns the #{index} that matches the test data for the 1st row" do
          expect(@data[0][index.to_sym]).to eq(expected[index.to_sym])
        end
      }

      # 2nd row to test
      keys_to_test.keys.each{|index|
          it "returns the #{index} that matches the test data for the 2nd row" do
            expect(@data[1][index.to_sym]).to eq(expected_values[index.to_sym])
          end
      }



    end
    end
  end

