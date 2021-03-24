require 'rspec'

FILE_NAME = "NSPL_MONTH_YEAR_UK.csv".freeze

describe 'Postcode' do
  include RSpecRegisterApiServiceMixin

  let(:postcode_gateway) { Gateway::PostcodesGateway.new }

  before(:all) do
    HttpStub.enable_webmock
  end

  after(:all) do
    HttpStub.off
  end

  context "When we call the import_address_matching task" do
    before do
      allow(STDOUT).to receive(:puts)
      EnvironmentStub
        .all
        .with("bucket_name", "test-bucket")
        .with("file_name", FILE_NAME)
      HttpStub.s3_get_object(FILE_NAME, get_postcode_csv)
    end

    it "Then we can fetch an existing postcode" do
      get_task("import_postcode").invoke

      postcodes = postcode_gateway.fetch("BR8 7QP")

      expect(postcodes.first).to eq({postcode: "BR8 7QP", longitude: 0.148926, latitude: 51.403454})
    end

    it "Then we can fetch an existing outcode for an non existing postcode" do
      get_task("import_postcode").invoke

      postcodes = postcode_gateway.fetch("BR8 AAA")

      expect(postcodes.first).to eq({outcode: "BR8", longitude: 0.1474355, latitude: 51.401588000000004})
    end
  end
end

def get_postcode_csv
  "pcd,pcd2,pcds,dointr,doterm,usertype,oseast1m,osnrth1m,osgrdind,oa11,cty,ced,laua,ward,hlthau,nhser,ctry,rgn,pcon,eer,teclec,ttwa,pct,nuts,park,lsoa11,msoa11,wz11,ccg,bua11,buasd11,ru11ind,oac11,lat,long,lep1,lep2,pfa,imd,calncv,stp\n" \
  "\"CA8 7JG\",\"CA8  7JG\",\"CA8 7JG\",\"200006\",\"\",\"0\",\"366033\",\"0564878\",\"1\",\"E00139875\",\"E99999999\",\"E99999999\",\"E06000057\",\"E05009122\",\"E18000001\",\"E40000009\",\"E92000001\",\"E12000001\",\"E14000746\",\"E15000001\",\"E24000017\",\"E30000064\",\"E17000001\",\"E05009122\",\"E99999999\",\"E01027484\",\"E02005728\",\"E33002161\",\"E38000130\",\"E34999999\",\"E35999999\",\"F2\",\"1B1\",54.977344,-2.532215,\"E37000025\",\"\",\"E23000007\",17158,\"E56000029\",\"E54000050\"\n" \
  "\"BR8 7QP\",\"BR8  7QP\",\"BR8 7QP\",\"198001\",\"\",\"0\",\"549571\",\"0169349\",\"1\",\"E00003520\",\"E13000002\",\"E99999999\",\"E09000006\",\"E05000114\",\"E18000007\",\"E40000003\",\"E92000001\",\"E12000007\",\"E14000872\",\"E15000007\",\"E24000016\",\"E30000234\",\"E16000004\",\"E05000114\",\"E99999999\",\"E01000720\",\"E02000145\",\"E33032837\",\"E38000244\",\"E34999999\",\"E35999999\",\"D1\",\"1C1\",51.403454,0.148926,\"E37000051\",\"\",\"E23000001\",3404,\"E56000010\",\"E54000030\"\n" \
  "\"BR8 7QW\",\"BR8  7QW\",\"BR8 7QW\",\"198001\",\"\",\"0\",\"549374\",\"0168928\",\"1\",\"E00003520\",\"E13000002\",\"E99999999\",\"E09000006\",\"E05000114\",\"E18000007\",\"E40000003\",\"E92000001\",\"E12000007\",\"E14000872\",\"E15000007\",\"E24000016\",\"E30000234\",\"E16000004\",\"E05000114\",\"E99999999\",\"E01000720\",\"E02000145\",\"E33032837\",\"E38000244\",\"E34999999\",\"E35999999\",\"D1\",\"1C1\",51.399722,0.145945,\"E37000051\",\"\",\"E23000001\",3404,\"E56000010\",\"E54000030\"\n"
end

