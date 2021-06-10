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

    context "it reads the data from the CSV" do
      before { Timecop.freeze(2021, 06, 10) }
      after { Timecop.return }

      let(:date_today) { Time.new.strftime("%Y-%m") }
      let(:ordered_met_office_directory) { Dir.glob("spec/fixtures/met_office_data/#{date_today}/*").sort }

      it "reads the files from the latest directory from the Met Office" do
        expected_file_names = %w"Region_01-Thames_Valley.csv Region_05-Severn_Valley.csv Region_16-Wales.csv Region_14-East_Scotland.csv"
        expected_file_names.each do |file_name|
          expect(ordered_met_office_directory.find{ |item| item.include?(file_name) }).not_to be_nil
        end
      end

      it "parses each file into a Ruby object" do
        ordered_met_office_directory.each do |file_name|
          expect{CSV.parse(File.read(file_name))}.not_to raise_error
        end
      end

      it "finds the value for Jan 2021 in the Heating deg days table" do
        parsed_data = CSV.parse(File.read(ordered_met_office_directory.first))
        heating_table_start = parsed_data.find_index { |row| row.first == "Heating deg days - base temp 15.5C"}
        cooling_table_start = parsed_data.find_index { |row| row.first == "Cooling deg days - base temp 15.5C"}
        heating_table_full = parsed_data[(heating_table_start + 3)..(cooling_table_start - 2)]
        number_of_columns = 13

        expect(heating_table_full[0].length).to eq(number_of_columns)
        expect(heating_table_full.find {|year| year.first == "2021"}[1]).to eq("56.7")
      end
    end

  end
end
