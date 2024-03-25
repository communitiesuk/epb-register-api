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

    let(:expected_data) do
      ["'BT1 1AA', 54.602444, -5.922291, 'Northern Ireland'",
       "'BT1 1AE', 54.602557, -5.93151, 'Northern Ireland'",
       "'BT1 1AF', 54.602557, -5.93151, 'Northern Ireland'",
       "'AL1 1AA', 51.749084, -0.341337, 'East of England'",
       "'CA6 7BB', 55.08748, -2.527787, 'North East'",
       "'BB0 1GR', 53.753449, -2.464232, 'North West'",
       "'BB18 6JR', 53.922805, -2.122499, 'Yorkshire and The Humber'",
       "'B79 0PJ', 52.677817, -1.561515, 'East Midlands'",
       "'B1  1AA', 52.47666, -1.903535, 'West Midlands'",
       "'BR1 1AA', 51.401546, 0.015415, 'London'",
       "'BH21 6AS', 50.867805, -1.847897, 'South East'",
       "'BA1 0AA', 51.378846, -2.35556, 'South West'",
       "'CF1 1AA', 51.469744, -3.187692, 'Wales'"]
    end

    let(:expected_outcodes)  do
      { "BT1" => { latitude: [54.602444, 54.602557, 54.602557], longitude: [-5.922291, -5.93151, -5.93151], region: ["Northern Ireland", "Northern Ireland", "Northern Ireland"] },
        "AL1" => { latitude: [51.749084], longitude: [-0.341337], region: ["East of England"] },
        "CA6" => { latitude: [55.08748], longitude: [-2.527787], region: ["North East"] },
        "BB0" => { latitude: [53.753449], longitude: [-2.464232], region: ["North West"] },
        "BB18" => { latitude: [53.922805], longitude: [-2.122499], region: ["Yorkshire and The Humber"] },
        "B79" => { latitude: [52.677817], longitude: [-1.561515], region: ["East Midlands"] },
        "B1" => { latitude: [52.47666], longitude: [-1.903535], region: ["West Midlands"] },
        "BR1" => { latitude: [51.401546], longitude: [0.015415], region: %w[London] },
        "BH21" => { latitude: [50.867805], longitude: [-1.847897], region: ["South East"] },
        "BA1" => { latitude: [51.378846], longitude: [-2.35556], region: ["South West"] },
        "CF1" => { latitude: [51.469744], longitude: [-3.187692], region: %w[Wales] } }
    end

    let(:file_io) do
      file = "spec/fixtures/postcodes_test.csv"
      File.open(file)
    end

    let(:postcode_csv) do
      CSV.new(file_io, headers: true)
    end

    it "sends the file to the exec method from a zip" do
      expect { use_case.execute(postcode_csv) }.not_to raise_error
    end

    it "sends expected args, excluding Scottish postcodes, to insert_postcode_batch" do
      use_case.execute(postcode_csv)
      expect(gateway).to have_received(:insert_postcode_batch).exactly(1).with(expected_data).times
    end

    it "sends expected args, excluding Scottish outcodes, to insert_outcodes" do
      use_case.execute(postcode_csv)
      expect(gateway).to have_received(:insert_outcodes).exactly(1).with(expected_outcodes).times
    end

    context "when the remaining number of row is greater than the buffer size" do
      it "inserts postcodes in batches" do
        use_case.execute(postcode_csv, buffer_size: 10)
        expect(gateway).to have_received(:insert_postcode_batch).exactly(2).times
      end
    end
  end
end
