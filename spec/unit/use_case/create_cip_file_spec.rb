describe "UseCase::CreateCipFile" do
  context "read degrees day data stored by the Met office" do
    let(:gateway_double) { instance_double(Gateway::MetOfficeGateway) }
    subject { UseCase::CreateCipFile.new(gateway_double) }

    context "it reads the file names from the gateway" do
      it "and returns them" do
        gateway_file_names = %w[
          Region_01-Thames_Valley.csv
          Region_02-South_East_England.csv
          Region_03-South_England.csv
          Region_04-South_West_England.csv
        ]
        allow(gateway_double).to receive(:read_degrees_day_data).and_return(
          gateway_file_names,
        )
        expect(subject.execute).to eq(gateway_file_names)
      end

      it "and excludes the Scottish files from the return" do
        gateway_file_names = %w[
          Region_01-Thames_Valley.csv
          Region_02-South_East_England.csv
          Region_03-South_England.csv
          Region_04-South_West_England.csv
          Region_13-West_Scotland.csv
          Region_14-East_Scotland.csv
          Region_15-North_East_Scotland.csv
          Region_16-Wales.csv
          Region_18-North_West_Scotland.csv
        ]
        non_scottish_file_names = %w[
          Region_01-Thames_Valley.csv
          Region_02-South_East_England.csv
          Region_03-South_England.csv
          Region_04-South_West_England.csv
          Region_16-Wales.csv
        ]
        allow(gateway_double).to receive(:read_degrees_day_data).and_return(
          gateway_file_names,
        )
        expect(subject.execute).to eq(non_scottish_file_names)
      end

      it "raises an error if there are no file names" do
        gateway_file_names = []
        allow(gateway_double).to receive(:read_degrees_day_data).and_return(
          gateway_file_names,
        )
        expect { subject.execute }.to raise_error(
          UseCase::CreateCipFile::NoFiles,
        )
      end
    end
  end
end
