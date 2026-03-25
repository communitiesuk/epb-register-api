describe Gateway::PostcodesGateway do
  subject(:gateway) { described_class.new }

  describe "#fetch" do
    before do
      add_postcodes("SW1A 2AA", 51.503541, -0.12767, "London")
      add_postcodes("EH1 2NG", 55.948961, -3.201479, "Scotland")

      # Insert border postcode with a Scottish region
      add_postcodes("DG14 0TF", 55.056368, -2.958697, "Scotland")

      # Insert border postcode with an England region
      add_postcodes("TD9 0TU", 55.155731, -2.745026, "North West")
    end

    context "when the postcode is present in the postcode_geolocation table" do
      it "returns the longitude and latitude of a postcode" do
        postcode = "SW1A 2AA"
        expect(gateway.fetch(postcode)).to eq [{ latitude: 51.503541, longitude: -0.12767, postcode: "SW1A 2AA" }]
      end
    end

    context "when the postcode is not present in the postcode_geolocation table" do
      before do
        add_outcodes("SW1A", 51.50197821468924, -0.13386012429378527, "London")
      end

      it "returns the longitude and latitude for the outcode from the postcode_outcode_geolocations table" do
        postcode = "SW1A 1XP"
        expect(gateway.fetch(postcode)).to eq [{ latitude: 51.50197821468924, longitude: -0.13386012429378527, outcode: "SW1A" }]
      end

      it "returns an empty array when the outcode is not present in the postcode_geolocation table" do
        postcode = "X1 1XX"
        expect(gateway.fetch(postcode)).to eq []
      end
    end

    context "when a scottish flag is present" do
      it "returns the longitude and latitude for a Scottish postcode" do
        postcode = "EH1 2NG"
        expect(gateway.fetch(postcode, is_scottish: true)).to eq [{ latitude: 55.948961, longitude: -3.201479, postcode: "EH1 2NG" }]
      end

      it "returns the longitude and latitude for a postcode on the Scotland and England border" do
        postcode = "TD9 0TU"
        expect(gateway.fetch(postcode, is_scottish: true)).to eq [{ latitude: 55.155731, longitude: -2.745026, postcode: "TD9 0TU" }]
      end

      it "does not return the longitude and latitude for a English postcode" do
        postcode = "SW1A 2AA"
        expect(gateway.fetch(postcode, is_scottish: true)).to eq []
      end

      context "when the postcode is not present in the postcode_geolocation table" do
        it "returns the longitude and latitude for a Scottish outcode" do
          add_outcodes("EH1", 55.95226832245438, -3.1921253002610883, "Scotland")
          postcode = "EH1 2XX"
          expect(gateway.fetch(postcode, is_scottish: true)).to eq [{ latitude: 55.95226832245438, longitude: -3.1921253002610883, outcode: "EH1" }]
        end

        it "does not add return values for a English outcode" do
          add_outcodes("SW1A", 51.50197821468924, -0.13386012429378527, "London")
          postcode = "SW1A 1XP"
          expect(gateway.fetch(postcode, is_scottish: true)).to eq []
        end

        it "return the longitude and latitude for a English outcode on the border" do
          add_outcodes("TD15", 55.751010875339, -2.0134154539295355, "North East")
          postcode = "TD15 2ZZ"
          expect(gateway.fetch(postcode, is_scottish: true)).to eq [{ latitude: 55.751010875339, longitude: -2.0134154539295355, outcode: "TD15" }]
        end
      end
    end

    context "when the scottish flag is not present" do
      it "does not return the longitude and latitude for a Scottish postcode" do
        postcode = "EH1 2NG"
        expect(gateway.fetch(postcode)).to eq []
      end

      it "returns the longitude and latitude for a postcode on the Scotland and England border" do
        postcode = "DG14 0TF"
        expect(gateway.fetch(postcode)).to eq [{ latitude: 55.056368, longitude: -2.958697, postcode: "DG14 0TF" }]
      end

      context "when the postcode is not present in the postcode_geolocation table" do
        it "does not return values for a Scottish outcode" do
          add_outcodes("EH1", 55.95226832245438, -3.1921253002610883, "Scotland")
          postcode = "EH1 2XX"
          expect(gateway.fetch(postcode)).to eq []
        end

        it "return the longitude and latitude for a Scottish outcode on the border" do
          add_outcodes("TD9", 55.3994824546498, -2.777752726750858, "Scotland")
          postcode = "TD9 2ZZ"
          expect(gateway.fetch(postcode)).to eq [{ latitude: 55.3994824546498, longitude: -2.777752726750858, outcode: "TD9" }]
        end
      end
    end
  end
end
