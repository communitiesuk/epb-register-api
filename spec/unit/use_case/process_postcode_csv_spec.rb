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
    end

    it "sends the file to the exec method" do
      file = "spec/fixtures/postcodes_test.csv.zip"
      file_io = File.open(file)

      Zip::InputStream.open(file_io) do |csv_io|
        while (entry = csv_io.get_next_entry)
          next unless entry.size.positive?

          puts "[#{Time.now}] #{entry.name} was unzipped with a size of #{entry.size} bytes"
          postcode_csv = CSV.new(csv_io, headers: true)
          expect { use_case.execute(postcode_csv) }.not_to raise_error
        end
      end
    end
  end
end
