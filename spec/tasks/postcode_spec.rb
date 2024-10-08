require "rspec"

describe "Postcode Rake to import ONS postcode lookups" do
  include RSpecRegisterApiServiceMixin
  let(:described_class) { get_task("maintenance:import_postcode_geo_location") }
  let(:get_postcode_csv) do
    "pcd,pcd2,pcds,dointr,doterm,usertype,oseast1m,osnrth1m,osgrdind,oa11,cty,ced,laua,ward,hlthau,nhser,ctry,rgn,pcon,eer,teclec,ttwa,pct,nuts,park,lsoa11,msoa11,wz11,ccg,bua11,buasd11,ru11ind,oac11,lat,long,lep1,lep2,pfa,imd,calncv,stp\n" \
      "\"CA8 7JG\",\"CA8  7JG\",\"CA8 7JG\",\"200006\",\"\",\"0\",\"366033\",\"0564878\",\"1\",\"E00139875\",\"E99999999\",\"E99999999\",\"E06000057\",\"E05009122\",\"E18000001\",\"E40000009\",\"E92000001\",\"E12000001\",\"E14000746\",\"E15000001\",\"E24000017\",\"E30000064\",\"E17000001\",\"E05009122\",\"E99999999\",\"E01027484\",\"E02005728\",\"E33002161\",\"E38000130\",\"E34999999\",\"E35999999\",\"F2\",\"1B1\",54.977344,-2.532215,\"E37000025\",\"\",\"E23000007\",17158,\"E56000029\",\"E54000050\"\n" \
      "\"BR8 7QP\",\"BR8  7QP\",\"BR8 7QP\",\"198001\",\"\",\"0\",\"549571\",\"0169349\",\"1\",\"E00003520\",\"E13000002\",\"E99999999\",\"E09000006\",\"E05000114\",\"E18000007\",\"E40000003\",\"E92000001\",\"E12000007\",\"E14000872\",\"E15000007\",\"E24000016\",\"E30000234\",\"E16000004\",\"E05000114\",\"E99999999\",\"E01000720\",\"E02000145\",\"E33032837\",\"E38000244\",\"E34999999\",\"E35999999\",\"D1\",\"1C1\",51.403454,0.148926,\"E37000051\",\"\",\"E23000001\",3404,\"E56000010\",\"E54000030\"\n" \
      "\"BR8 7QW\",\"BR8  7QW\",\"BR8 7QW\",\"198001\",\"\",\"0\",\"549374\",\"0168928\",\"1\",\"E00003520\",\"E13000002\",\"E99999999\",\"E09000006\",\"E05000114\",\"E18000007\",\"E40000003\",\"E92000001\",\"E12000007\",\"E14000872\",\"E15000007\",\"E24000016\",\"E30000234\",\"E16000004\",\"E05000114\",\"E99999999\",\"E01000720\",\"E02000145\",\"E33032837\",\"E38000244\",\"E34999999\",\"E35999999\",\"D1\",\"1C1\",51.399722,0.145945,\"E37000051\",\"\",\"E23000001\",3404,\"E56000010\",\"E54000030\"\n"
  end
  let(:postcode_gateway) { Gateway::PostcodesGateway.new }
  let(:file_name) { "NSPL_MONTH_YEAR_UK.csv" }

  before(:all) { HttpStub.enable_webmock }

  after(:all) { HttpStub.off }

  context "when we call the import_address_matching task" do
    before do
      allow($stdout).to receive(:puts)
      EnvironmentStub
        .all
        .with("ONS_POSTCODE_BUCKET_NAME", "test-bucket")
        .with("FILE_NAME", file_name)

      HttpStub.s3_get_object(file_name, get_postcode_csv)
    end

    after do
      EnvironmentStub.remove(%w[ONS_POSTCODE_BUCKET_NAME FILE_NAME])
    end

    it "Then we can fetch an existing postcode" do
      described_class.invoke

      postcodes = postcode_gateway.fetch("BR8 7QP")

      expect(postcodes.first).to eq(
        { postcode: "BR8 7QP", longitude: 0.148926, latitude: 51.403454 },
      )
    end

    it "Then we can fetch an existing outcode for an non existing postcode" do
      described_class.invoke

      postcodes = postcode_gateway.fetch("BR8 AAA")

      expect(postcodes.first).to eq(
        { outcode: "BR8", longitude: 0.1474355, latitude: 51.401588000000004 },
      )
    end
  end

  context "when the rake does not run" do
    before do
      allow($stdout).to receive(:puts)
    end

    context "when the bucket_name has not been passed" do
      it "raises a Boundary::ArgumentMissing" do
        expect { described_class.invoke }.to raise_error Boundary::ArgumentMissing, "A required argument is missing: bucket_name"
      end
    end

    context "when the file name has not been passed" do
      before do
        EnvironmentStub
          .all
          .with("ONS_POSTCODE_BUCKET_NAME", "test-bucket")
      end

      after do
        EnvironmentStub.remove(%w[ONS_POSTCODE_BUCKET_NAME])
      end

      it "raises a Boundary::ArgumentMissing error" do
        expect { described_class.invoke }.to raise_error Boundary::ArgumentMissing, /file_name/
      end
    end

    context "when the file name is not correct" do
      before do
        EnvironmentStub
          .all
          .with("ONS_POSTCODE_BUCKET_NAME", "test-bucket")
          .with("FILE_NAME", "ONSPD_AUG_2024_UK.csv.zip")
      end

      after do
        EnvironmentStub.remove(%w[ONS_POSTCODE_BUCKET_NAME FILE_NAME])
      end

      it "raises a Boundary::InvalidArgument error" do
        expect { described_class.invoke }.to raise_error Boundary::InvalidArgument, "A required argument is is invalid: file name ONSPD_AUG_2024_UK.csv.zip must start with 'NSPL'"
      end
    end
  end
end
