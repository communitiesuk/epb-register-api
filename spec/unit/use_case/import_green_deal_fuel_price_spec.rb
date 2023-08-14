describe UseCase::ImportGreenDealFuelPrice do
  let(:use_case) { described_class.new(gateway) }
  let(:gateway) { instance_double(Gateway::GreenDealFuelPriceGateway) }

  describe "#exec" do
    context "when data can be downloaded from the http" do
      before do
        allow(gateway).to receive(:bulk_insert)
        allow(gateway).to receive(:get_data).and_return(price_data)
      end

      let(:price_data) do
        ["1,1,90,3.97,2019/Dec/03 12:12",
         "1,9,90,3.97,2019/Dec/03 12:12",
         "1,1,95,3.74,2022/Jun/30 14:30",
         "1,9,95,3.74,2022/Jun/30 14:30"]
      end

      it "calls the exec and passes the data to gateway" do
        use_case.execute
        expect(gateway).to have_received(:bulk_insert).with(price_data).exactly(1).times
      end

      it "converts the download data into the expected array", aggregate_failures: true do
        file_data = File.open("spec/fixtures/fuel_price_data.dat.txt")

        stub_request(:get, "https://www.ncm-pcdb.org.uk/pcdb/pcdf2012.dat")
          .with(
            headers: {
              "Accept" => "*/*",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "Host" => "www.ncm-pcdb.org.uk",
              "User-Agent" => "Ruby",
            },
          )
        .to_return(status: 200, body: file_data, headers: {})
        expect { use_case.execute }.not_to raise_error
        expect(gateway).to have_received(:bulk_insert).exactly(1).times
      end
    end

    context "when the HTTP request fails" do
      before do
        WebMock.enable!
        allow(gateway).to receive(:bulk_insert)
        allow(gateway).to receive(:get_data)
        stub_request(:get, "https://www.ncm-pcdb.org.uk/pcdb/pcdf2012.dat").to_raise(StandardError)
      end

      after do
        WebMock.disable!
      end

      it "calls the exec that raises a custom error and returns before call the gateway", aggregate_failures: true do
        expect { use_case.execute }.to raise_error(UseCase::ImportGreenDealFuelPrice::NoDataException)
        expect(gateway).to have_received(:bulk_insert).exactly(0).times
      end
    end

    context "when the HTTP request returns no data" do
      before do
        allow(gateway).to receive(:bulk_insert)
        allow(gateway).to receive(:get_data).and_return("<h1>no data</h1>")
      end

      it "calls the exec that raises a custom error and returns before call the gateway", aggregate_failures: true do
        expect { use_case.execute }.to raise_error(UseCase::ImportGreenDealFuelPrice::NoDataException)
        expect(gateway).to have_received(:bulk_insert).exactly(0).times
      end
    end

    context "when the HTTP request returns empty array" do
      before do
        allow(gateway).to receive(:get_data).and_return([])
        allow(gateway).to receive(:bulk_insert)
      end

      it "calls the exec that raises a custom error and returns before call the gateway" do
        expect { use_case.execute }.to raise_error(UseCase::ImportGreenDealFuelPrice::NoDataException)
        expect(gateway).to have_received(:bulk_insert).exactly(0).times
      end
    end
  end
end
