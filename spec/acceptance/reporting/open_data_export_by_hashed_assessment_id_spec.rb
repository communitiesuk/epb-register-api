require_relative "open_data_export_test_helper"

describe "Acceptance::Reports::OpenDataExport By Hashed Ids", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  scheme_id = nil

  before do
    Timecop.freeze(2021, 0o2, 22, 0, 0, 0)
    scheme_id = lodge_assessor
  end

  after do
    WebMock.disable!
    Timecop.return
  end

  let(:statistics) do
    gateway = Gateway::OpenDataLogGateway.new
    gateway.fetch_latest_statistics
  end

  context "when an assessment is lodged" do
    context "when it is a domestic assessment" do
      before do
        add_postcodes("SW1A 2AA", 51.5045, 0.0865, "London")
        add_outcodes("SW1A", 51.5045, 0.4865, "London")

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

        add_countries
        add_assessment_country_ids
      end

      context "when it calls the use case to extract the data by hashed assessment id" do
        context "with the domestic certificates" do
          let(:use_case) { UseCase::ExportOpenDataDomesticByHashedId.new }
          let(:csv_data) do
            Helper::ExportHelper.to_csv(
              use_case
                .execute(%w[71fdb53a3a3da2cf98ae87c819dfc958866ead832a214cc960da52d2edaaaad6 5cb9fa3be789df637c7c20acac4e19c5ebf691f0f0d78f2a1b5f30c8b336bba6], 0)
                .sort_by! { |item| item[:assessment_id] },
            )
          end
          let(:fixture_csv) { read_csv_fixture("domestic") }
          let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

          it "returns the data exported to a CSV object to match the .csv fixture" do
            expect(parsed_exported_data.length).to eq(fixture_csv.length)
            expect((parsed_exported_data.headers - fixture_csv.headers) | (fixture_csv.headers - parsed_exported_data.headers)).to be_empty
          end

          it "returns the data exported for row 1 object to match same row in the .csv fixture" do
            fixture_data = fixture_csv[0].to_hash.transform_values { |v| v.presence || "" }
            expect(parsed_exported_data[0].to_hash).to eq(fixture_data)
          end

          it "returns the data exported for row 2 object to match same row in the .csv fixture" do
            expect(parsed_exported_data[1].to_hash).to eq fixture_csv[1].to_hash
          end

          context "when there are no lodged assessments with those hashed assessment ids" do
            let(:csv_data) do
              Helper::ExportHelper.to_csv(
                use_case
                  .execute(%w[4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a a154b93d62db9b77c82f6b11ba4a4a4056816572180c95e0bc5d486b905d4996], 0)
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

          it "transfers the file to the S3 bucket with the correct filename, body and headers" do
            get_task("open_data:export_assessments_by_hashed_assessment_id").invoke("71fdb53a3a3da2cf98ae87c819dfc958866ead832a214cc960da52d2edaaaad6 5cb9fa3be789df637c7c20acac4e19c5ebf691f0f0d78f2a1b5f30c8b336bba6", "for_odc")

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
            it "prefixes the CSV filename with `test/` so it's stored in a separate folder in the S3 bucket" do
              HttpStub.s3_put_csv(
                "test/open_data_export_by_hashed_assessment_id_sap-rdsap_#{Time.now.strftime('%F')}_1.csv",
              )

              get_task("open_data:export_assessments_by_hashed_assessment_id").invoke("71fdb53a3a3da2cf98ae87c819dfc958866ead832a214cc960da52d2edaaaad6 5cb9fa3be789df637c7c20acac4e19c5ebf691f0f0d78f2a1b5f30c8b336bba6", "not_for_odc")

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
        expect { get_task("open_data:export_assessments_by_hashed_assessment_id").invoke }.to raise_error(Boundary::ArgumentMissing, /A required argument is missing: hashed_assessment_ids./)
      end

      it "raises an error when a wrong type of hashed_assessment_ids is provided" do
        expect { get_task("open_data:export_assessments_by_hashed_assessment_id").invoke("not_a_hashed_id", "for_odc") }.to raise_error(Boundary::OpenDataEmpty, /split_hashed_assessments_id:/)
      end

      it "raises an error when hashed_assessment_ids is provided but type_of_export is not" do
        expect { get_task("open_data:export_assessments_by_hashed_assessment_id").invoke("4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a") }.to raise_error(Boundary::ArgumentMissing, /You must specify 'for_odc' or 'not_for_odc'/)
      end

      it "raises an error when the type_of_export argument is not one of the accepted types" do
        expect { get_task("open_data:export_assessments_by_hashed_assessment_id").invoke("4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a", "for_dean") }.to raise_error(Boundary::ArgumentMissing, /You must specify 'for_odc' or 'not_for_odc'/)
      end
    end

    context "when there are no lodged assessments with those hashed assessment ids" do
      it "returns a no data to export error" do
        hashed_assessment_id = "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a a154b93d62db9b77c82f6b11ba4a4a4056816572180c95e0bc5d486b905d4996"
        expect { get_task("open_data:export_assessments_by_hashed_assessment_id").invoke(hashed_assessment_id, "for_odc") }.to raise_error(Boundary::OpenDataEmpty, /split_hashed_assessments_id:/)
      end
    end
  end
end
