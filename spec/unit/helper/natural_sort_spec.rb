describe Helper::NaturalSort do

    it "sorts by comparing postcode" do
      addresses = [
        {
          address_line1: "20 Oxford Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          town: "",
          postcode: "W2D 1BS",
        },
        {
          address_line1: "20 Oxford Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          town: "",
          postcode: "W1D 1BS",
        },
        {
          address_line1: "20 Oxford Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          town: "",
          postcode: "WED 1BS",
        },
        {
          address_line1: "20 Oxford Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          town: "",
          postcode: "W3D 1BS",
        },
      ]

      Helper::NaturalSort.sort!(addresses)

      expect(addresses).to eq(
        [
          {
            address_line1: "20 Oxford Street",
            address_line2: "",
            address_line3: "",
            address_line4: "",
            town: "",
            postcode: "W1D 1BS",
          },
          {
            address_line1: "20 Oxford Street",
            address_line2: "",
            address_line3: "",
            address_line4: "",
            town: "",
            postcode: "W2D 1BS",
          },
          {
            address_line1: "20 Oxford Street",
            address_line2: "",
            address_line3: "",
            address_line4: "",
            town: "",
            postcode: "W3D 1BS",
          },
          {
            address_line1: "20 Oxford Street",
            address_line2: "",
            address_line3: "",
            address_line4: "",
            town: "",
            postcode: "WED 1BS",
          },
        ],
      )
    end

    it "sorts by property number when on the first address line" do
      addresses = [
        {
          address_line1: "2 Harvard Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          town: "London",
          postcode: "W1D 1BS",
        },
        {
          address_line1: "20 Harvard Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          town: "London",
          postcode: "W1D 1BS",
        },
        {
          address_line1: "10 Harvard Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          town: "London",
          postcode: "W1D 1BS",
        },
        {
          address_line1: "1 Harvard Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          town: "London",
          postcode: "W1D 1BS",
        },
      ]

      Helper::NaturalSort.sort!(addresses)

      expect(addresses).to eq(
       [
         {
           address_line1: "1 Harvard Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "London",
           postcode: "W1D 1BS",
         },
         {
           address_line1: "2 Harvard Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "London",
           postcode: "W1D 1BS",
         },
         {
           address_line1: "10 Harvard Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "London",
           postcode: "W1D 1BS",
         },
         {
           address_line1: "20 Harvard Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "London",
           postcode: "W1D 1BS",
         },
        ],
       )
    end

    it "sorts by property number when they also contain letters" do
      addresses = [
        {
          address_line1: "2c Harvard Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          town: "London",
          postcode: "W1D 1BS",
        },
        {
          address_line1: "2b Harvard Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          town: "London",
          postcode: "W1D 1BS",
        },
        {
          address_line1: "2a Harvard Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          town: "London",
          postcode: "W1D 1BS",
        },
      ]

      Helper::NaturalSort.sort!(addresses)

      expect(addresses).to eq(
       [
         {
           address_line1: "2a Harvard Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "London",
           postcode: "W1D 1BS",
         },
         {
           address_line1: "2b Harvard Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "London",
           postcode: "W1D 1BS",
         },
         {
           address_line1: "2c Harvard Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "London",
           postcode: "W1D 1BS",
         },
       ]
     )
    end

    it "sorts by property number when they are on different address lines" do
      addresses = [
        {
          address_line1: "20 Harvard Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          town: "London",
          postcode: "W1D 1BS",
        },
        {
          address_line1: "The Cottage",
          address_line2: "15 Harvard Street",
          address_line3: "",
          address_line4: "",
          town: "London",
          postcode: "W1D 1BS",
        },
        {
          address_line1: "14 Harvard Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          town: "London",
          postcode: "W1D 1BS",
        },
      ]

      Helper::NaturalSort.sort!(addresses)

      expect(addresses).to eq(
       [
         {
           address_line1: "14 Harvard Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "London",
           postcode: "W1D 1BS",
         },
         {
           address_line1: "The Cottage",
           address_line2: "15 Harvard Street",
           address_line3: "",
           address_line4: "",
           town: "London",
           postcode: "W1D 1BS",
         },
         {
           address_line1: "20 Harvard Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "London",
           postcode: "W1D 1BS",
         },
       ]
     )
    end

    it "sorts when an address has no property number" do
      addresses = [
        {
          address_line1: "20 Harvard Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          town: "London",
          postcode: "W1D 1BS",
        },
        {
          address_line1: "The Cottage",
          address_line2: "Harvard Street",
          address_line3: "",
          address_line4: "",
          town: "London",
          postcode: "W1D 1BS",
        },
        {
          address_line1: "14 Harvard Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          town: "London",
          postcode: "W1D 1BS",
        },
        {
          address_line1: "British Cottage",
          address_line2: "Harvard Street",
          address_line3: "",
          address_line4: "",
          town: "London",
          postcode: "W1D 1BS",
        },
      ]

      Helper::NaturalSort.sort!(addresses)

      expect(addresses).to eq(
       [
         {
           address_line1: "The Cottage",
           address_line2: "Harvard Street",
           address_line3: "",
           address_line4: "",
           town: "London",
           postcode: "W1D 1BS",
         },
         {
           address_line1: "British Cottage",
           address_line2: "Harvard Street",
           address_line3: "",
           address_line4: "",
           town: "London",
           postcode: "W1D 1BS",
         },
         {
           address_line1: "14 Harvard Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "London",
           postcode: "W1D 1BS",
         },
         {
           address_line1: "20 Harvard Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "London",
           postcode: "W1D 1BS",
         },
       ]
     )
    end

    it "can sort addresses on the same street with differing town values" do
      addresses = [
      {
        address_line1: "199 THORPE ROAD",
        address_line2: "KIRBY CROSS",
        address_line3: "",
        address_line4: "",
        town: "KIRBY CROSS",
        postcode: "CO13 0NH",
      },
      {
        address_line1: "200, Thorpe Road",
        address_line2: "Kirby Cross",
        address_line3: "",
        address_line4: "",
        town: "FRINTON-ON-SEA",
        postcode: "CO13 0NH",
      },
      {
        address_line1: "171, Thorpe Road",
        address_line2: "Kirby Cross",
        address_line3: "",
        address_line4: "",
        town: "FRINTON-ON-SEA",
        postcode: "CO13 0NH",
      }
    ]

    Helper::NaturalSort.sort!(addresses)

    expect(addresses).to eq(
      [
        {
          address_line1: "171, Thorpe Road",
          address_line2: "Kirby Cross",
          address_line3: "",
          address_line4: "",
          town: "FRINTON-ON-SEA",
          postcode: "CO13 0NH",
        },
        {
          address_line1: "199 THORPE ROAD",
          address_line2: "KIRBY CROSS",
          address_line3: "",
          address_line4: "",
          town: "KIRBY CROSS",
          postcode: "CO13 0NH",
        },
        {
          address_line1: "200, Thorpe Road",
          address_line2: "Kirby Cross",
          address_line3: "",
          address_line4: "",
          town: "FRINTON-ON-SEA",
          postcode: "CO13 0NH",
        }
      ]
    )
    end

    it "can sort addresses which contain flats" do

    end
end
