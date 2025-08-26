require "rspec"

describe "Postcode Rake to import ONS postcode lookups" do
  include RSpecRegisterApiServiceMixin
  let(:described_class) { get_task("maintenance:import_postcode_geo_location") }
  let(:get_postcode_csv) do
    "pcd7,pcd8,pcds,dointr,doterm,usrtypind,east1m,north1m,gridind,oa21cd,cty25cd,ced25cd,lad25cd,wd25cd,nhser24cd,ctry25cd,rgn25cd,pcon24cd,ttwa15cd,itl25cd,npark16cd,lsoa21cd,msoa21cd,wz11cd,sicbl24cd,bua24cd,ruc21ind,oac11ind,lat,long,lep21cd1,lep21cd2,pfa23cd,imd20ind,icb23cd\n" \
      "\"CA8 7JG\",\"CA8  7JG\",\"CA8 7JG\",\"200006\",\"\",\"0\",\"366033\",\"564878\",\"1\",\"E00139875\",\"E99999999\",\"E99999999\",\"E06000057\",\"E05016114\",\"E40000012\",\"E92000001\",\"E12000001\",\"E14001285\",\"E30000064\",\"E06000057\",\"E65000001\",\"E01027484\",\"E02005728\",\"E33002161\",\"E38000130\",\"E63999999\",\"RSN1\",\"1B1\",54.977349,-2.532223,\"E37000025\",\"\",\"E23000007\",17158,\"E54000050\"\n" \
      "\"BR8 7QP\",\"BR8  7QP\",\"BR8 7QP\",\"198001\",\"\",\"0\",\"549571\",\"169349\",\"1\",\"E00003520\",\"E13000002\",\"E99999999\",\"E09000006\",\"E05014007\",\"E40000003\",\"E92000001\",\"E12000007\",\"E14001417\",\"E30000234\",\"E09000006\",\"E65000001\",\"E01000720\",\"E02000145\",\"E33032837\",\"E38000244\",\"E63999999\",\"UN1\",\"1C1\",51.403453,0.148952,\"E37000051\",\"\",\"E23000001\",3404,\"E54000030\"\n" \
      "\"BR8 7QW\",\"BR8  7QW\",\"BR8 7QW\",\"198001\",\"\",\"0\",\"549370\",\"168924\",\"1\",\"E00003520\",\"E13000002\",\"E99999999\",\"E09000006\",\"E05014007\",\"E40000003\",\"E92000001\",\"E12000007\",\"E14001417\",\"E30000234\",\"E09000006\",\"E65000001\",\"E01000720\",\"E02000145\",\"E33032837\",\"E38000244\",\"E63999999\",\"UN1\",\"1C1\",51.399687,0.145885,\"E37000051\",\"\",\"E23000001\",3404,\"E54000030\"\n"
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
        { postcode: "BR8 7QP", longitude: 0.148952, latitude: 51.403453 },
      )
    end

    it "Then we can fetch an existing outcode for an non existing postcode" do
      described_class.invoke

      postcodes = postcode_gateway.fetch("BR8 AAA")

      expect(postcodes.first).to eq(
        { outcode: "BR8", longitude: 0.1474185, latitude: 51.40157 },
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
