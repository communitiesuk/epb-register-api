require "rspec"

describe "Address Matching Rake to process sample addresses from S3" do
  include RSpecRegisterApiServiceMixin
  let(:described_class) { get_task("dev_scripts:s3_sample_address_match") }
  let(:address_without_match_args) do
    {
      postcode: "DE21 7FY",
      address_line_1: "61 Kirkleys Avenue South",
      address_line_2: "Spondon",
      address_line_3: "",
      address_line_4: "",
      town: "DERBY",
    }
  end

  let(:address_with_multiple_matches_args) do
    {
      postcode: "PL6 8LB",
      address_line_1: "Vine Cottage",
      address_line_2: "Marsh Close",
      address_line_3: "",
      address_line_4: "",
      town: "PLYMOUTH",
    }
  end

  let(:address_sample_csv) do
    csv_data = <<~CSV
      postcode,address_line1,address_line2,address_line3,address_line4,town,address_id,source,type_of_assessment

      GL6 8DS,BUBBLEWELL HOUSE,HIGHT STREET,STROUD,,GLOUCESTERSHIRE,RRN-0000-0000-0000-0000-0000,epb_bulk_linking,RdSAP
      PE33 9DR,5 Hatherley Gardens,Barton Bendish,"","",KING'S LYNN,UPRN-100090976153,lodgement,RdSAP
      CW12 4DZ,30 West End Cottages,"","","",CONGLETON,UPRN-100010046240,lodgement,RdSAP
      BR2 0EF,44 Martins Road,"","","",BROMLEY,UPRN-100020405884,lodgement,RdSAP
      W6 9LQ,210 Riverside Gardens,"","","",LONDON,UPRN-000034007234,lodgement,RdSAP
      CB23 5DG,28 School Lane,Lower Cambourne,"","",CAMBRIDGE,UPRN-200002748771,lodgement,RdSAP
      IP33 3TF,122b Newmarket Road,"","","",BURY ST. EDMUNDS,UPRN-010023130162,lodgement,RdSAP
      DE21 7FY,61 Kirkleys Avenue South,Spondon,"","",DERBY,UPRN-100030328722,lodgement,RdSAP
      SW1Y 6DN,"",33 Jermyn Street,"","",LONDON,UPRN-010033577561,epb_team_update,CEPC
      BS31 2TR,22 Willow Walk,Keynsham,"","",BRISTOL,UPRN-100120042114,lodgement,RdSAP
      AL1 2DT,18 Trevelyan Place,St. Stephens Hill,"","",ST. ALBANS,UPRN-200003642713,lodgement,RdSAP
      B5 7FW,404 Boulevard Plaza,654A Bristol Street ,"",,Birmingham,RRN-0000-0009-0532-8124-3353,lodgement,SAP
      PL6 8LB,Vine Cottage,Marsh Close,"","",PLYMOUTH,UPRN-100040464000,lodgement,RdSAP
      GL4 6LP,38B,Birchall Avenue,Matson,,GLOUCESTER,RRN-0000-0010-0032-3090-0243,adjusted_at_lodgement,SAP
      WS2 0DG,20 Wrexham Avenue,"","","",Walsall,RRN-0000-0010-0622-4023-3103,lodged_with_rrn,RdSAP
      CF14 5LJ,70 Trenchard Drive,Llanishen,"",,CARDIFF,UPRN-010095462805,lodgement,SAP
      W2 1UZ,82 John Aird Court,"","","",LONDON,UPRN-100022769083,lodgement,RdSAP
      EN11 8LR,20 Warners Avenue,"","","",HODDESDON,UPRN-000148024797,lodgement,RdSAP
      PO5 1NS,111 Boulton Road,"","","",SOUTHSEA,UPRN-001775007218,lodgement,RdSAP
      CW2 7AF,Apartment 18 St. Andrews Corner,Stalbridge Road,"","",CREWE,RRN-0000-0018-0932-7022-3103,lodged_with_rrn,SAP
    CSV

    csv_data
  end
  let(:addressing_gateway) do
    Gateway::AddressingApiGateway.new
  end

  let(:addressing_api_endpoint) do
    "http://test-addressing.gov.uk/match-address"
  end

  let(:file_name) { "addresses.csv" }
  let(:results_file_name) { "addresses_matched.csv" }

  before(:all) { HttpStub.enable_webmock }

  after(:all) do
    HttpStub.off
    EnvironmentStub.remove(%w[AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY BUCKET_NAME AWS_DEFAULT_REGION AWS_REGION FILE_NAME])
  end

  context "when we call the import_address_matching task" do
    before do
      allow($stdout).to receive(:puts)
      EnvironmentStub
        .all
        .with("BUCKET_NAME", "test-bucket")
        .with("FILE_NAME", file_name)

      WebMock.stub_request(:put, "https://test-bucket.s3.eu-west-2.amazonaws.com/addresses_matched.csv").to_return(status: 200)
      HttpStub.s3_get_object(file_name, address_sample_csv)

      OauthStub.token
      WebMock
        .stub_request(
          :post,
          addressing_api_endpoint,
        )
        .to_return(status: 200, body: "sample")
      allow(Gateway::AddressingApiGateway).to receive(:new).and_return(addressing_gateway)
      allow(addressing_gateway).to receive(:match_address).and_return([{ "uprn" => "199990129", "address" => "Flat 1, New Bridge Lane, PC01 A11", "confidence" => "99.3" }])

      allow(addressing_gateway).to receive(:match_address).with(address_without_match_args).and_return([])
      allow(addressing_gateway).to receive(:match_address).with(address_with_multiple_matches_args).and_return(
        [
          { "uprn" => "100000001", "address" => "Vine Cottage, Marsh Close, PL6 8LB", "confidence" => "99.3" },
          { "uprn" => "100000002", "address" => "Vine Kiosk, Marsh Close, PL6 8LB", "confidence" => "80.3" },
        ],
      )

      described_class.invoke
    end

    it "downloads the file from S3" do
      expect(WebMock).to have_requested(:get, "https://test-bucket.s3.eu-west-2.amazonaws.com/#{file_name}")
    end

    it "calls the addressing_api_gateway" do
      expect(addressing_gateway).to have_received(:match_address).with(anything).exactly(20).times
    end

    it "calls the addressing_api_gateway with the right arguments" do
      expect(addressing_gateway).to have_received(:match_address).with(**address_without_match_args).once
    end

    it "defaults to 'none' for addresses without a match" do
      expect(a_request(:put, "https://test-bucket.s3.eu-west-2.amazonaws.com/#{results_file_name}").with do |req|
        req.body.include? "DE21 7FY,61 Kirkleys Avenue South,Spondon,\"\",\"\",DERBY,UPRN-100030328722,lodgement,RdSAP,none,none,none\n"
      end).to have_been_made
    end

    it "chooses the address match with most confidence" do
      expect(a_request(:put, "https://test-bucket.s3.eu-west-2.amazonaws.com/#{results_file_name}").with do |req|
        req.body.include? "PL6 8LB,Vine Cottage,Marsh Close,\"\",\"\",PLYMOUTH,UPRN-100040464000,lodgement,RdSAP,100000001,\"Vine Cottage, Marsh Close, PL6 8LB\",99.3\n"
      end).to have_been_made
    end

    it "uploads the result file to S3" do
      expect(WebMock).to have_requested(:put, "https://test-bucket.s3.eu-west-2.amazonaws.com/#{results_file_name}")
    end
  end

  context "when the rake does not run" do
    context "when the bucket name has not been passed" do
      before do
        EnvironmentStub.remove(%w[BUCKET_NAME])
      end

      after do
        EnvironmentStub
          .with("BUCKET_NAME", "test-bucket")
      end

      it "raises a Boundary::ArgumentMissing" do
        expect { described_class.invoke }.to raise_error Boundary::ArgumentMissing, "A required argument is missing: bucket_name"
      end
    end

    context "when the file name has not been passed" do
      before do
        EnvironmentStub
          .with("BUCKET_NAME", "test-bucket")
      end

      it "raises a Boundary::ArgumentMissing" do
        expect { described_class.invoke }.to raise_error Boundary::ArgumentMissing, "A required argument is missing: file_name"
      end
    end
  end
end
