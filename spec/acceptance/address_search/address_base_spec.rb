describe "Acceptance::AddressBase" do
  include RSpecRegisterApiServiceMixin

  context "with a valid sql request" do
    let(:address_data) do
      ActiveRecord::Base.connection.execute(
        "SELECT * FROM address_base WHERE uprn = '73546792'",
      )
    end

    before do
      ActiveRecord::Base.connection.execute(
        "INSERT INTO
              address_base
                (
                  uprn,
                  postcode,
                  address_line1,
                  address_line2,
                  address_line3,
                  address_line4,
                  town
                )
            VALUES(
              '73546792',
              'NE24 2TW',
              '5 Grimal Place',
              'Skewit Road',
              '',
              '',
              'London'
            )",
      )
    end

    it "returns a valid address" do
      expect(address_data.entries.first).to eq(
        {
          "address_line1" => "5 Grimal Place",
          "address_line2" => "Skewit Road",
          "address_line3" => "",
          "address_line4" => "",
          "postcode" => "NE24 2TW",
          "town" => "London",
          "uprn" => "73546792",
        },
      )
    end
  end
end
