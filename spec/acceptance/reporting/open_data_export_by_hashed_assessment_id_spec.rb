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

        # # created_at is now being used instead of date_registered for the date boundaries
        # ActiveRecord::Base
        #   .connection.execute "UPDATE assessments SET created_at = '2020-05-04 00:00:00.000000' WHERE  assessment_id = '0000-0000-0000-0000-1004'"
      end

      context "when it calls the use case to extract the data by hashed assessment id" do
        context "with the domestic certificates" do
          let(:use_case) { UseCase::ExportOpenDataDomestic.new }
          let(:csv_data) do
            Helper::ExportHelper.to_csv(
              use_case
                .execute_using_hashed_assessment_id(%w[71fdb53a3a3da2cf98ae87c819dfc958866ead832a214cc960da52d2edaaaad6 5cb9fa3be789df637c7c20acac4e19c5ebf691f0f0d78f2a1b5f30c8b336bba6], 0)
                .sort_by! { |item| item[:assessment_id] },
            )
          end
          let(:fixture_csv) { read_csv_fixture("domestic") }
          let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

          it "returns the data exported to a csv object to match the .csv fixture" do
            expect(parsed_exported_data.length).to eq(fixture_csv.length)
            expect(parsed_exported_data.headers - fixture_csv.headers).to eq([])
          end

          2.times do |i|
            it "returns the data exported for row #{i} object to match same row in the .csv fixture " do
              expect(
                redact_lodgement_datetime(parsed_exported_data[i]) -
                  redact_lodgement_datetime(fixture_csv[i]),
              ).to eq([])
            end
          end

          context "when there are no lodged assessments with those hashed assessment ids" do
            let(:csv_data) do
              Helper::ExportHelper.to_csv(
                use_case
                  .execute_using_hashed_assessment_id(%w[4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a a154b93d62db9b77c82f6b11ba4a4a4056816572180c95e0bc5d486b905d4996], 0)
              .sort_by! { |item| item[:assessment_id] },
              )
            end

            it "returns no data" do
              expect(csv_data.length).to eq(0)
            end
          end
        end
      end

      context "when we invoke the Open Data Communities export by hashed assessment id Rake directly" do
        context "when we set the correct environment variables to send the certificate data to S3" do
          let(:fixture_csv) { read_csv_fixture("domestic") }

          before do
            EnvironmentStub
              .all

            HttpStub.s3_put_csv("open_data_export_by_hashed_assessment_id_sap-rdsap_#{Time.now.strftime('%F')}_1.csv")
          end

          it "transfers the file to the S3 bucket with the correct filename, body and headers " do
            get_task("open_data:export_assessments_by_hashed_assessment_id").invoke(%w[71fdb53a3a3da2cf98ae87c819dfc958866ead832a214cc960da52d2edaaaad6 5cb9fa3be789df637c7c20acac4e19c5ebf691f0f0d78f2a1b5f30c8b336bba6], "for_odc")

            expect(WebMock).to have_requested(
              :put,
              "#{HttpStub::S3_BUCKET_URI}open_data_export_by_hashed_assessment_id_sap-rdsap_#{Time.now.strftime('%F')}_1.csv",
            ).with(
              body: regex_body(fixture_csv.headers),
              headers: {
                "Host" => "s3.eu-west-2.amazonaws.com",
              },
            )
          end

          context "when running a test export" do
            it "prefixes the csv filename with `test/` so it's stored in a separate folder in the S3 bucket" do
              HttpStub.s3_put_csv(
                "test/open_data_export_by_hashed_assessment_id_sap-rdsap_#{Time.now.strftime('%F')}_1.csv",
              )

              get_task("open_data:export_assessments_by_hashed_assessment_id").invoke(%w[71fdb53a3a3da2cf98ae87c819dfc958866ead832a214cc960da52d2edaaaad6 5cb9fa3be789df637c7c20acac4e19c5ebf691f0f0d78f2a1b5f30c8b336bba6], "not_for_odc")

              expect(WebMock).to have_requested(
                :put,
                "#{HttpStub::S3_BUCKET_URI}test/open_data_export_by_hashed_assessment_id_sap-rdsap_#{Time.now.strftime('%F')}_1.csv",
              )
            end
          end
        end
      end
    end
  end

  context "when invoking the Open Data Communities export by hashed assessment id rake directly" do
    context "when we invoke with incorrect arguments" do
      it "raises an error when no arguments are provided" do
        expect { get_task("open_data:export_assessments_by_hashed_assessment_id").invoke }.to raise_error Boundary::ArgumentMissing
      end

      it "raises an error when a wrong type of hashed_assessment_ids is provided" do
        expect { get_task("open_data:export_assessments_by_hashed_assessment_id").invoke("for_dean") }.to raise_error Boundary::ArgumentMissing
      end

      it "raises an error when type of export is provided but hashed_assessment_ids argument is not" do
        expect { get_task("open_data:export_assessments_by_hashed_assessment_id").invoke("for_odc") }.to raise_error Boundary::ArgumentMissing
      end
    end

    context "when we set the correct arguments and a date range with no assessments" do
      it "returns a no data to export error" do
        hashed_assessment_id = %w[4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a a154b93d62db9b77c82f6b11ba4a4a4056816572180c95e0bc5d486b905d4996]
        expect { get_task("open_data:export_assessments_by_hashed_assessment_id").invoke(hashed_assessment_id, "for_odc") }.to raise_error Boundary::OpenDataEmpty
      end
    end
  end
end
