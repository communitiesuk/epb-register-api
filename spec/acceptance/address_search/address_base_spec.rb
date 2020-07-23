describe "Acceptance::AddressBase" do
  include RSpecRegisterApiServiceMixin

  context "with a valid sql request" do
    let(:address_data) do
      ActiveRecord::Base.connection.execute(
        "SELECT * FROM address_base WHERE uprn = '73546792'",
      )
    end

    let(:response) do
      JSON.parse(
          assertive_get(
              "/api/search/addresses?postcode=A0%200AA",
              [200],
              true,
              nil,
              %w[address:search],
              ).body,
          symbolize_names: true,
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
            VALUES
              (
                '73546792',
                'A0 0AA',
                '5 Grimal Place',
                'Skewit Road',
                '',
                '',
                'London'
              ),
              (
                '73546793',
                'A0 0AA',
                '7 Grimal Place',
                'Skewit Road',
                '',
                '',
                'London'
              ),
              (
                '73546794',
                'A0 0AA',
                '9 Grimal Place',
                'Skewit Road',
                '',
                '',
                'London'
              ),
              (
                '736042792',
                'NE23 1TW',
                '5 Grimiss Place',
                'Suggton Road',
                '',
                '',
                'Newcastle'
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
          "postcode" => "A0 0AA",
          "town" => "London",
          "uprn" => "73546792",
        },
      )
    end

    it 'returns a valid address when a postcode is searched for ' do
      expect(response[:data][:addresses]).to eq(
                                                    {
                                                        :addressLine1 => "5 Grimal Place",
                                                        :addressLine2 => "Skewit Road",
                                                        :addressLine3 => "",
                                                        :addressLine4 => "",
                                                        :postcode => "A0 0AA",
                                                        :town => "London",
                                                        :uprn => "73546792",
                                                    },
                                                    )
    end
  end
end
