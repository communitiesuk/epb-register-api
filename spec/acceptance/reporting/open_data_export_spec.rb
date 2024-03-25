require_relative "open_data_export_test_helper"

describe "Acceptance::Reports::OpenDataExport", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  scheme_id = nil

  before(:all) { scheme_id = lodge_assessor }

  after { WebMock.disable! }

  let(:statistics) do
    gateway = Gateway::OpenDataLogGateway.new
    gateway.fetch_latest_statistics
  end

  context "when an assessment is lodged" do
    context "when it is a domestic assessment" do
      before do
        add_postcodes("A0 0AA", 51.5045, 0.0865, "London")
        add_outcodes("A0", 51.5045, 0.4865, "London")

        domestic_rdsap_xml =
          get_assessment_xml(
            "RdSAP-Schema-20.0.0",
            "0000-0000-0000-0000-0004",
            test_start_date,
          )
        lodge_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )

        domestic_rdsap_xml =
          get_assessment_xml(
            "RdSAP-Schema-20.0.0",
            "0000-0000-0000-0000-1004",
            test_to_date,
          )
        lodge_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )

        domestic_sap_xml =
          get_assessment_xml(
            "SAP-Schema-18.0.0",
            "0000-0000-0000-0000-1100",
            test_start_date,
          )
        domestic_sap_building_reference_number = domestic_sap_xml.at("UPRN")
        domestic_sap_building_reference_number.children =
          "RRN-0000-0000-0000-0000-0023"
        lodge_assessment(
          assessment_body: domestic_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
          schema_name: "SAP-Schema-18.0.0",
        )

        # created_at is now being used instead of date_registered for the date boundaries
        ActiveRecord::Base
          .connection.execute "UPDATE assessments SET created_at = '2020-05-04 00:00:00.000000' WHERE  assessment_id = '0000-0000-0000-0000-1004'"
      end

      context "when it calls the use case to extract the data" do
        context "with the domestic certificates" do
          let(:use_case) { UseCase::ExportOpenDataDomestic.new }
          let(:csv_data) do
            Helper::ExportHelper.to_csv(
              use_case
                .execute(test_start_date, 0, datetime_today)
                .sort_by! { |item| item[:assessment_id] },
            )
          end
          let(:fixture_csv) { read_csv_fixture("domestic") }
          let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

          it "returns the data exported to a CSV object to match the .csv fixture" do
            expect(parsed_exported_data.length).to eq(fixture_csv.length)
            expect(parsed_exported_data.headers - fixture_csv.headers).to eq([])
          end

          2.times do |i|
            it "returns the data exported for row #{i} object to match same row in the .csv fixture" do
              expect(
                redact_lodgement_datetime(parsed_exported_data[i]) -
                  redact_lodgement_datetime(fixture_csv[i]),
              ).to eq([])
            end
          end

          context "when there are no lodged assessments between two dates" do
            let(:csv_data) do
              Helper::ExportHelper.to_csv(
                use_case
                  .execute("2021-03-02", 0, "2021-03-03")
                  .sort_by! { |item| item[:assessment_id] },
              )
            end

            it "returns no data" do
              expect(csv_data.length).to eq(0)
            end
          end
        end

        context "with the domestic recommendation reports" do
          let(:use_case) { UseCase::ExportOpenDataDomesticrr.new }
          let(:csv_data) do
            Helper::ExportHelper.to_csv(
              use_case
                .execute(test_start_date, 0, datetime_today)
                .sort_by! do |item|
                  [item[:assessment_id], item[:improvement_item]]
                end,
            )
          end
          let(:fixture_csv) { read_csv_fixture("domestic_rr") }
          let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

          it "returns the data exported to a CSV object to match the .csv fixture" do
            expect(parsed_exported_data.headers - fixture_csv.headers).to eq([])
            expect(parsed_exported_data.length).to eq(fixture_csv.length)
          end

          4.times do |i|
            it "returns the data exported for row #{i} object to match same row in the .csv fixture" do
              expect(parsed_exported_data[i].to_a - fixture_csv[i].to_a).to eq(
                [],
              )
            end
          end

          context "when there are no lodged assessments between two dates" do
            let(:csv_data) do
              Helper::ExportHelper.to_csv(
                use_case
                  .execute("2021-03-02", 0, "2021-03-03")
                  .sort_by! { |item| item[:assessment_id] },
              )
            end

            it "returns no data" do
              expect(csv_data.length).to eq(0)
            end
          end
        end
      end

      context "when we invoke the Open Data Communities export Rake directly" do
        context "when we set the correct environment variables to send the certificate data to S3" do
          let(:fixture_csv) { read_csv_fixture("domestic") }

          before do
            EnvironmentStub
              .all

            HttpStub.s3_put_csv(file_name("SAP-RDSAP"))
          end

          it "transfers the file to the S3 bucket with the correct filename, body and headers" do
            assessment_type = "SAP-RDSAP"
            date_to = "2021-07-01"
            date_from = test_start_date
            get_task("open_data:export_assessments").invoke("for_odc", assessment_type, date_from, date_to)

            expect(WebMock).to have_requested(
              :put,
              "#{HttpStub::S3_BUCKET_URI}open_data_export_sap-rdsap_#{Time.now.strftime('%F')}_1.csv",
            ).with(
              body: regex_body(fixture_csv.headers),
              headers: {
                "Host" => "s3.eu-west-2.amazonaws.com",
              },
            )
          end

          context "when running a test export" do
            it "prefixes the csv filename with `test/` so it's stored in a separate folder in the S3 bucket" do
              assessment_type = "SAP-RDSAP"
              date_from = test_start_date
              date_to = "2021-07-01"
              HttpStub.s3_put_csv(
                "test/open_data_export_sap-rdsap_#{Time.now.strftime('%F')}_1.csv",
              )

              get_task("open_data:export_assessments").invoke("not_for_odc", assessment_type, date_from, date_to)

              expect(WebMock).to have_requested(
                :put,
                "#{HttpStub::S3_BUCKET_URI}test/open_data_export_sap-rdsap_#{Time.now.strftime('%F')}_1.csv",
              )
            end
          end
        end

        context "when we set correct environment variables to send the recommendation report data to S3" do
          before do
            EnvironmentStub
              .all

            HttpStub.s3_put_csv(file_name("SAP-RDSAP-RR"))
          end

          let(:fixture_csv) { read_csv_fixture("domestic_rr") }

          it "check the http stub matches the request disabled in web mock using the filename, body and headers" do
            assessment_type = "SAP-RDSAP-RR"
            date_from = test_start_date
            date_to = "2021-07-01"
            get_task("open_data:export_assessments").invoke("for_odc", assessment_type, date_from, date_to)

            expect(WebMock).to have_requested(
              :put,
              "#{HttpStub::S3_BUCKET_URI}open_data_export_sap-rdsap-rr_#{Time.now.strftime('%F')}_1.csv",
            ).with(
              body: regex_body(fixture_csv.headers),
              headers: {
                "Host" => "s3.eu-west-2.amazonaws.com",
              },
            )
          end
        end
      end
    end

    context "when it is a commercial/non-domestic assessment" do
      before do
        add_postcodes("A0 0AA", 51.5045, 0.0865, "London")
        add_outcodes("A0", 51.5045, 0.4865, "London")

        2.times do |i|
          non_domestic_xml =
            get_assessment_xml(
              "CEPC-8.0.0",
              "0000-0000-0000-0000-000#{i}",
              test_start_date,
              "cepc",
            )
          lodge_assessment(
            assessment_body: non_domestic_xml.to_xml,
            accepted_responses: [201],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            override: true,
            schema_name: "CEPC-8.0.0",
          )
        end

        out_of_range_non_domestic_xml =
          get_assessment_xml(
            "CEPC-8.0.0",
            "0000-0000-0000-0000-0010",
            test_to_date,
            "cepc",
          )
        lodge_assessment(
          assessment_body: out_of_range_non_domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        cepc_rr_xml =
          get_recommendations_xml(
            "CEPC-8.0.0",
            test_start_date,
            "cepc+rr",
            "1111",
          )
        lodge_assessment(
          assessment_body: cepc_rr_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        cepc_rr_xml =
          get_recommendations_xml("CEPC-8.0.0", test_to_date, "cepc+rr", "1112")
        lodge_assessment(
          assessment_body: cepc_rr_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        # created_at is now being used instead of date_registered for the date boundaries
        ActiveRecord::Base
          .connection.execute "UPDATE assessments SET created_at = '2019-05-04 00:00:00.000000' WHERE  assessment_id IN ('0000-0000-0000-0000-0010', '1112-0000-0000-0000-0002', '1112-0000-0000-0000-0003')"
      end

      context "when it calls the use case to extract the data" do
        context "with the commercial/non-domestic certificates" do
          let(:use_case) { UseCase::ExportOpenDataCommercial.new }

          let(:csv_data) do
            Helper::ExportHelper.to_csv(
              use_case.execute(test_start_date, 0, datetime_today),
            )
          end

          let(:fixture_csv) { read_csv_fixture("commercial") }

          let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

          let(:first_commercial_assessment) do
            parsed_exported_data.find do |item|
              item["ASSESSMENT_ID"] ==
                "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a"
            end
          end

          let(:second_commercial_assessment) do
            parsed_exported_data.find do |item|
              item["ASSESSMENT_ID"] ==
                "55ce7d026c13e923d26cbfb0d6ed60734d3270ba981d629a168bb8eb2da3f8c4"
            end
          end

          it "returns the data exported to a csv object to match the .csv fixture" do
            expect(fixture_csv.headers - parsed_exported_data.headers).to eq([])
            expect(parsed_exported_data.length).to eq(3)
          end

          it "returns the data exported for row 1 object to match same row in the .csv fixture" do
            expect(
              redact_lodgement_datetime(first_commercial_assessment) -
                redact_lodgement_datetime(fixture_csv[0]),
            ).to eq([])
          end

          it "returns the data exported for row 2 object to match same row in the .csv fixture" do
            expect(
              redact_lodgement_datetime(second_commercial_assessment) -
                redact_lodgement_datetime(fixture_csv[1]),
            ).to eq([])
          end
        end

        context "with the commercial/non Domestic recommendation reports" do
          let(:use_case) { UseCase::ExportOpenDataCepcrr.new }
          let(:csv_data) do
            Helper::ExportHelper.to_csv(
              use_case.execute(test_start_date, 0, datetime_today),
            )
          end
          let(:fixture_csv) { read_csv_fixture("commercial_rr") }
          let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

          it "returns the data exported to a csv object to match the .csv fixture" do
            # parsed_exported_data.map {|it| pp it}
            # fixture_csv.map {|it| pp it}
            expect(parsed_exported_data.length).to eq(fixture_csv.length)
            expect(parsed_exported_data.headers - fixture_csv.headers).to eq([])
          end

          5.times do |i|
            it "returns the data exported for row #{i} object to match same row in the .csv fixture" do
              expect(parsed_exported_data[i].to_a - fixture_csv[i].to_a).to eq(
                [],
              )
            end
          end
        end
      end

      context "when we invoke the Open Data Communities export Rake directly" do
        context "when we set the correct environment variables to send the certificate data to S3" do
          before do
            EnvironmentStub
              .all
            HttpStub.s3_put_csv(file_name("CEPC"))
          end

          let(:fixture_csv) { read_csv_fixture("commercial") }

          it "check the http stub matches the request disabled in web mock using the filename, body and headers" do
            assessment_type = "CEPC"
            date_from = test_start_date
            date_to = "2021-07-01"
            get_task("open_data:export_assessments").invoke("for_odc", assessment_type, date_from, date_to)

            expect(WebMock).to have_requested(
              :put,
              "#{HttpStub::S3_BUCKET_URI}open_data_export_cepc_#{Time.now.strftime('%F')}_1.csv",
            ).with(
              body: regex_body(fixture_csv.headers),
              headers: {
                "Host" => "s3.eu-west-2.amazonaws.com",
              },
            )
          end
        end

        context "when setting the correct environment variables invoke the task to send the recommendation report data to S3" do
          before do
            EnvironmentStub
              .all

            HttpStub.s3_put_csv(file_name("CEPC-RR"))
          end

          let(:fixture_csv) { read_csv_fixture("commercial_rr") }

          it "check the http stub matches the request disabled in web mock using the filename, body and headers" do
            assessment_type = "CEPC-RR"
            date_from = test_start_date
            date_to = "2021-07-01"
            get_task("open_data:export_assessments").invoke("for_odc", assessment_type, date_from, date_to)

            expect(WebMock).to have_requested(
              :put,
              "#{HttpStub::S3_BUCKET_URI}open_data_export_cepc-rr_#{Time.now.strftime('%F')}_1.csv",
            ).with(
              body: regex_body(fixture_csv.headers),
              headers: {
                "Host" => "s3.eu-west-2.amazonaws.com",
              },
            )
          end
        end
      end
    end

    context "when it is a DEC assessment" do
      before do
        add_postcodes("A0 0AA", 51.5045, 0.0865, "London")
        add_outcodes("A0", 51.5045, 0.4865, "London")

        dec_xml =
          get_assessment_xml(
            "CEPC-8.0.0",
            "0000-0000-0000-0000-0003",
            test_start_date,
            "dec",
          )
        lodge_assessment(
          assessment_body: dec_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        dec_xml =
          get_assessment_xml(
            "CEPC-8.0.0",
            "0000-0000-0000-0000-0012",
            test_to_date,
            "dec",
          )
        lodge_assessment(
          assessment_body: dec_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        dec_rr_xml =
          get_recommendations_xml(
            "CEPC-8.0.0",
            test_start_date,
            "dec+rr",
            "1111",
          )
        lodge_assessment(
          assessment_body: dec_rr_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        dec_rr_xml =
          get_recommendations_xml("CEPC-8.0.0", test_to_date, "dec+rr", "1112")
        lodge_assessment(
          assessment_body: dec_rr_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        ActiveRecord::Base
          .connection.execute "UPDATE assessments SET created_at = '2019-05-04 00:00:00.000000' WHERE  assessment_id IN ('0000-0000-0000-0000-0012', '1112-0000-0000-0000-0004', '1112-0000-0000-0000-0005')"
      end

      context "when it calls the use case to extract the data" do
        context "with the DEC certificates" do
          let(:dec_use_case) { UseCase::ExportOpenDataDec.new }
          let(:first_dec_asssement) do
            parsed_exported_data.find do |item|
              item["ASSESSMENT_ID"] ==
                "36ae715ec66a32ed9ffcd7fe9a2c44d91dec1d72ee26263c17f354167be8dd4b"
            end
          end
          let(:second_dec_asssement) do
            parsed_exported_data.find do |item|
              item["ASSESSMENT_ID"] ==
                "427ad45e88b1183572234b464ba07b37348243d120db1c478da42eda435e48e4"
            end
          end
          let(:csv_data) do
            Helper::ExportHelper.to_csv(
              dec_use_case.execute(test_start_date, 0, datetime_today),
            )
          end

          let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

          let(:fixture_csv) { read_csv_fixture("dec") }

          it "returns the data exported to a csv object to match the .csv fixture" do
            expect(parsed_exported_data.headers - fixture_csv.headers).to eq([])
            expect(parsed_exported_data.length).to eq(fixture_csv.length)
          end

          it "returns the data exported for row 1 object to match same row in the .csv fixture" do
            expect(
              redact_lodgement_datetime(first_dec_asssement) -
                redact_lodgement_datetime(fixture_csv[0]),
            ).to eq([])
          end

          it "returns the data exported for row 2 to match same row in the .csv fixture" do
            expect(
              redact_lodgement_datetime(second_dec_asssement) -
                redact_lodgement_datetime(fixture_csv[1]),
            ).to eq([])
          end
        end

        context "with the DEC recommendation reports" do
          let(:use_case) { UseCase::ExportOpenDataDecrr.new }
          let(:csv_data) do
            Helper::ExportHelper.to_csv(
              use_case
                .execute(test_start_date, 0, datetime_today)
                .sort_by! { |key| key[:recommendation_item] },
            )
          end

          let(:fixture_csv) { read_csv_fixture("dec_rr") }
          let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

          it "returns the data exported to a csv object to match the .csv fixture" do
            expect(parsed_exported_data.length).to eq(fixture_csv.length)
            expect(parsed_exported_data.headers - fixture_csv.headers).to eq([])
          end

          5.times do |i|
            it "returns the data exported for row #{i} object to match same row in the .csv fixture" do
              expect(parsed_exported_data[i].to_a - fixture_csv[i].to_a).to eq(
                [],
              )
            end
          end
        end
      end

      context "when we invoke the Open Data Communities export Rake directly" do
        context "when we set the correct environment variables to send the certificate data to S3" do
          before do
            EnvironmentStub
              .all

            HttpStub.s3_put_csv(file_name("DEC"))
          end

          let(:regex_body_pattern) do
            fixture_headers = %w[
              YR1_ELECTRICITY_CO2,YR2_ELECTRICITY_CO2,YR1_HEATING_CO2,YR2_HEATING_CO2,YR1_RENEWABLES_CO2,YR2_RENEWABLES_CO2,AIRCON_PRESENT,AIRCON_KW_RATING,ESTIMATED_AIRCON_KW_RATING
            ]
            regex_body(fixture_headers)
          end

          it "check the http stub matches the request disabled in web mock using the filename, body and headers" do
            assessment_type = "DEC"
            date_from = test_start_date
            date_to = "2021-07-01"
            get_task("open_data:export_assessments").invoke("for_odc", assessment_type, date_from, date_to)

            expect(WebMock).to have_requested(
              :put,
              "#{HttpStub::S3_BUCKET_URI}open_data_export_dec_#{Time.now.strftime('%F')}_1.csv",
            ).with(
              body: regex_body_pattern,
              headers: {
                "Host" => "s3.eu-west-2.amazonaws.com",
              },
            )
          end
        end

        context "when we set correct environment variables to send the recommendation report data to S3" do
          before do
            EnvironmentStub
              .all

            HttpStub.s3_put_csv(file_name("DEC-RR"))
          end

          let(:fixture_csv) { read_csv_fixture("dec_rr") }

          it "check the http stub matches the request disabled in web mock using the filename, body and headers" do
            assessment_type = "DEC-RR"
            date_from = test_start_date
            date_to = "2021-07-01"
            get_task("open_data:export_assessments").invoke("for_odc", assessment_type, date_from, date_to)
            expect(WebMock).to have_requested(
              :put,
              "#{HttpStub::S3_BUCKET_URI}open_data_export_dec-rr_#{Time.now.strftime('%F')}_1.csv",
            ).with(
              body: regex_body(fixture_csv.headers),
              headers: {
                "Host" => "s3.eu-west-2.amazonaws.com",
              },
            )
          end
        end
      end
    end
  end

  context "when invoking the Open Data Communities export rake directly" do
    context "when we invoke with incorrect arguments" do
      it "raises an error when type of export is not provided" do
        expect { get_task("open_data:export_assessments").invoke }.to raise_error Boundary::ArgumentMissing
      end

      it "raises an error when a wrong type of export is provided" do
        expect { get_task("open_data:export_assessments").invoke("for_dean") }.to raise_error Boundary::ArgumentMissing
      end

      it "raises an error when type of export is provided but assessment_type argument is not" do
        expect { get_task("open_data:export_assessments").invoke("for_odc") }.to raise_error Boundary::ArgumentMissing
      end

      it "returns an error when the wrong type of assessment type is provided" do
        expect { get_task("open_data:export_assessments").invoke("for_odc", "TEST", Time.now.strftime("%F")) }.to raise_error Boundary::InvalidAssessment
      end
    end

    context "when we set the correct arguments and a date range with no assessments" do
      it "returns a no data to export error" do
        assessment_type = "SAP-RDSAP"
        date_from = "2018-12-01"
        date_to = "2019-12-07"
        expect { get_task("open_data:export_assessments").invoke("for_odc", assessment_type, date_from, date_to) }.to raise_error Boundary::OpenDataEmpty
      end
    end
  end

  context "when an assessment is lodged with lines breaks in the XML" do
    before do
      add_postcodes("A0 0AA", 51.5045, 0.0865, "London")
      add_outcodes("A0", 51.5045, 0.4865, "London")

      domestic_sap_xml =
        get_assessment_xml(
          "SAP-Schema-18.0.0",
          "0000-0000-0000-0000-1100",
          test_start_date,
        )
      updated_address_line_1 = domestic_sap_xml.at("Property Address Address-Line-1")
      updated_address_line_1.children = "1 Kitten Street\n"

      lodge_assessment(
        assessment_body: domestic_sap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
        schema_name: "SAP-Schema-18.0.0",
      )
    end

    context "with the domestic assessments" do
      let(:use_case) { UseCase::ExportOpenDataDomestic.new }
      let(:data) do
        use_case
           .execute(test_start_date, 0, "2021-02-28")
           .sort_by! { |item| item[:assessment_id] }
      end
      let(:cleaned_data) { Helper::ExportHelper.remove_line_breaks_from_hash_values(data) }
      let(:csv_data) { Helper::ExportHelper.to_csv(cleaned_data) }
      let(:fixture_csv) { read_csv_fixture("domestic_remove_line_break") }
      let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

      it "returns the csv values with no line breaks" do
        expect(
          redact_lodgement_datetime(parsed_exported_data[0]) -
            redact_lodgement_datetime(fixture_csv[0]),
        ).to eq([])
      end
    end

    context "when invoking the open data export rake" do
      before do
        EnvironmentStub
          .all
        HttpStub.s3_put_csv(file_name("SAP-RDSAP"))
      end

      it "returns the data without line breaks in the body" do
        assessment_type = "SAP-RDSAP"
        date_from = test_start_date
        get_task("open_data:export_assessments").invoke("for_odc", assessment_type, date_from, Time.now.strftime("%F"))

        expect(WebMock).not_to have_requested(
          :put,
          "#{HttpStub::S3_BUCKET_URI}open_data_export_sap-rdsap_#{Time.now.strftime('%F')}_1.csv",
        ).with(
          body: Regexp.new("1 Kitten Street\n"),
        )

        expect(WebMock).to have_requested(
          :put,
          "#{HttpStub::S3_BUCKET_URI}open_data_export_sap-rdsap_#{Time.now.strftime('%F')}_1.csv",
        ).with(
          body: Regexp.new("1 Kitten Street"),
        )
      end
    end

    context "when environment variables are set rather than arguments" do
      before do
        EnvironmentStub
          .all
        HttpStub.s3_put_csv(file_name("SAP-RDSAP"))
        EnvironmentStub.with("assessment_type", "SAP-RDSAP")
        EnvironmentStub.with("date_from", test_start_date)
        EnvironmentStub.with("date_to", "2021-07-01")
        EnvironmentStub.with("type_of_export", "for_odc")
      end

      after do
        EnvironmentStub.remove(%w[assessment_type date_from date_to type_of_export])
      end

      it "does not raise an argument error" do
        expect { get_task("open_data:export_assessments").invoke }.not_to raise_error
      end
    end

    context "when no dates are set or passed in and it the 1st day of the month" do
      before do
        Timecop.freeze(Time.utc(2021, 7, 1))
        EnvironmentStub
          .all
        HttpStub.s3_put_csv(file_name("SAP-RDSAP"))
        EnvironmentStub.with("assessment_type", "SAP-RDSAP")
        EnvironmentStub.with("type_of_export", "for_odc")
      end

      after do
        EnvironmentStub.remove(%w[assessment_type type_of_export])
      end

      it "does not raise an argument error" do
        expect { get_task("open_data:export_assessments").invoke }.not_to raise_error
      end
    end
  end
end
