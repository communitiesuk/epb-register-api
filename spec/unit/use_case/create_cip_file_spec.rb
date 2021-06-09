describe "UseCase::CreateCipFile" do

  context "read degrees day data stored by the Met office" do
    let(:gateway_double) {instance_double(Gateway::MetOfficeGateway)}
    subject { UseCase::CreateCipFile.new(gateway_double) }

    it 'gets data from the gateway and returns it' do
      file_names = ["Region_01-Thames_Valley.csv", "Region_02-South_East_England.csv", "Region_03-South_England.csv", "Region_04-South_West_England.csv"]
      allow(gateway_double).to receive(:read_degrees_day_data).and_return(file_names)
      expect(subject.execute).to eq(file_names)
    end
  end
end
