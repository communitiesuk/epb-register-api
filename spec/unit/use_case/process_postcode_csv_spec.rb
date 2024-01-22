describe UseCase::ProcessPostcodeCsv do
  let(:use_case) { described_class.new(gateway) }
  let(:gateway) { instance_double(Gateway::PostcodeGeolocationGateway) }

  before do
    allow($stdout).to receive(:puts)
  end

  it "instantiates the class with a gateway" do
    expect { use_case }.not_to raise_error
  end

  describe "#execute" do
    before do
      allow(gateway).to receive(:create_postcode_table)
      allow(gateway).to receive(:create_outcode_table)
      allow(gateway).to receive(:switch_postcode_table)
      allow(gateway).to receive(:switch_outcode_table)
      allow(gateway).to receive(:insert_postcode_batch)
      allow(gateway).to receive(:insert_outcodes)
    end

    let(:expected_data){
      ["'AB1 0AA', 57.101474, -2.242851, 'North East'", "'AB1 0AB', 57.102554, -2.246308, 'North West'", "'AB1 0AD', 57.100556, -2.248342, 'Eastern of England'"]
    }

    let(:expected_outcodes){
      {"AB1"=>{:latitude=>[57.101474, 57.102554, 57.100556], :longitude=>[-2.242851, -2.246308, -2.248342], :region=>["North East", "North West", "Eastern of England"]}}
    }


    let(:file_io){
      file = "spec/fixtures/postcodes_test.csv"
      File.open(file)
    }
    let(:postcode_csv){
      CSV.new(file_io, headers: true)
    }

    it "sends the file to the exec method from a zip" do
      expect { use_case.execute(postcode_csv) }.not_to raise_error
    end

    it "sends expected args to insert_postcode_batch" do
       use_case.execute(postcode_csv)
       expect(gateway).to have_received(:insert_postcode_batch).exactly(1).with(expected_data).times
    end

    it "sends expected args to insert_outcodes" do
      use_case.execute(postcode_csv)
      expect(gateway).to have_received(:insert_outcodes).exactly(1).with(expected_outcodes).times
    end



  end


end
