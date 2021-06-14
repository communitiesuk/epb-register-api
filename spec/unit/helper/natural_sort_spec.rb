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

  it "sorts by property number when address line 1 is empty" do
    addresses = [
      {
        address_line1: "",
        address_line2: "20 Harvard Street",
        address_line3: "",
        address_line4: "",
        town: "London",
        postcode: "W1D 1BS",
      },
      {
        address_line1: "",
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
                               address_line1: "",
                               address_line2: "15 Harvard Street",
                               address_line3: "",
                               address_line4: "",
                               town: "London",
                               postcode: "W1D 1BS",
                             },
                             {
                               address_line1: "",
                               address_line2: "20 Harvard Street",
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
           address_line1: "British Cottage",
           address_line2: "Harvard Street",
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

  it "sorts alphabetically when addresses have no property numbers" do
    addresses = [
      {
        address_line1: "SCHOOL HOUSE",
        address_line2: "BRADSHAW LANE",
        address_line3: "SLAITHWAITE",
        address_line4: "",
        town: "HUDDERSFIELD",
        postcode: "HD7 5UZ",
      },
      {
        address_line1: "Cockley Top Laund Road",
        address_line2: "Slaithwaite",
        address_line3: "",
        address_line4: "",
        town: "HUDDERSFIELD",
        postcode: "HD7 5UZ",
      },
      {
        address_line1: "Lower Bradshaw Barn",
        address_line2: "Bradshaw Lane",
        address_line3: "Slaithwaite",
        address_line4: "",
        town: "HUDDERSFIELD",
        postcode: "HD7 5UZ",
      },
      {
        address_line1: "Cargate Foot Farm",
        address_line2: "Slaithwaite",
        address_line3: "",
        address_line4: "",
        town: "HUDDERSFIELD",
        postcode: "HD7 5UZ",
      }
    ]

    Helper::NaturalSort.sort!(addresses)

    expect(addresses).to eq(
       [
         {
           address_line1: "Cargate Foot Farm",
           address_line2: "Slaithwaite",
           address_line3: "",
           address_line4: "",
           town: "HUDDERSFIELD",
           postcode: "HD7 5UZ",
         },
         {
           address_line1: "Cockley Top Laund Road",
           address_line2: "Slaithwaite",
           address_line3: "",
           address_line4: "",
           town: "HUDDERSFIELD",
           postcode: "HD7 5UZ",
         },
         {
           address_line1: "Lower Bradshaw Barn",
           address_line2: "Bradshaw Lane",
           address_line3: "Slaithwaite",
           address_line4: "",
           town: "HUDDERSFIELD",
           postcode: "HD7 5UZ",
         },
         {
           address_line1: "SCHOOL HOUSE",
           address_line2: "BRADSHAW LANE",
           address_line3: "SLAITHWAITE",
           address_line4: "",
           town: "HUDDERSFIELD",
           postcode: "HD7 5UZ",
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

  it "can sort addresses which contain flats at the same property number" do
    addresses = [
      {
        address_line1: "APARTMENT 3007",
        address_line2: "8 WALWORTH ROAD",
        address_line3: "LONDON",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "APARTMENT 2911",
        address_line2: "8 WALWORTH ROAD",
        address_line3: "LONDON",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "APARTMENT 3205",
        address_line2: "8 WALWORTH ROAD",
        address_line3: "LONDON",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
    ]

    Helper::NaturalSort.sort!(addresses)

    expect(addresses).to eq(
     [
       {
         address_line1: "APARTMENT 2911",
         address_line2: "8 WALWORTH ROAD",
         address_line3: "LONDON",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "APARTMENT 3007",
         address_line2: "8 WALWORTH ROAD",
         address_line3: "LONDON",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "APARTMENT 3205",
         address_line2: "8 WALWORTH ROAD",
         address_line3: "LONDON",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       }
     ]
    )
  end

  it "can sort addresses which are prefixed with a mix of flats & apartments at the same property number" do
    addresses = [
      {
        address_line1: "APARTMENT 3007",
        address_line2: "8 WALWORTH ROAD",
        address_line3: "LONDON",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "FLAT 2000",
        address_line2: "8 WALWORTH ROAD",
        address_line3: "LONDON",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "APARTMENT 3205",
        address_line2: "8 WALWORTH ROAD",
        address_line3: "LONDON",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "6000",
        address_line2: "8 WALWORTH ROAD",
        address_line3: "LONDON",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "FLAT 5000",
        address_line2: "8 WALWORTH ROAD",
        address_line3: "LONDON",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
    ]

    Helper::NaturalSort.sort!(addresses)

    expect(addresses).to eq(
     [
       {
         address_line1: "FLAT 2000",
         address_line2: "8 WALWORTH ROAD",
         address_line3: "LONDON",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "APARTMENT 3007",
         address_line2: "8 WALWORTH ROAD",
         address_line3: "LONDON",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "APARTMENT 3205",
         address_line2: "8 WALWORTH ROAD",
         address_line3: "LONDON",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "FLAT 5000",
         address_line2: "8 WALWORTH ROAD",
         address_line3: "LONDON",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "6000",
         address_line2: "8 WALWORTH ROAD",
         address_line3: "LONDON",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
     ]
   )
  end

  it "can sort addresses which contain the same flat number at different property numbers" do
    addresses = [
      {
        address_line1: "APARTMENT 1",
        address_line2: "9 WALWORTH ROAD",
        address_line3: "LONDON",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "APARTMENT 1",
        address_line2: "8 WALWORTH ROAD",
        address_line3: "LONDON",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "APARTMENT 1",
        address_line2: "10 WALWORTH ROAD",
        address_line3: "LONDON",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
    ]

    Helper::NaturalSort.sort!(addresses)

    expect(addresses).to eq(
      [
       {
         address_line1: "APARTMENT 1",
         address_line2: "8 WALWORTH ROAD",
         address_line3: "LONDON",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "APARTMENT 1",
         address_line2: "9 WALWORTH ROAD",
         address_line3: "LONDON",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "APARTMENT 1",
         address_line2: "10 WALWORTH ROAD",
         address_line3: "LONDON",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       }
     ]
   )
  end

  it "can sort addresses when the same numbered address appears twice" do
    addresses = [
      {
        address_line1: "10 WALWORTH ROAD",
        address_line2: "LONDON",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "10 WALWORTH ROAD",
        address_line2: "LONDON",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "9 WALWORTH ROAD",
        address_line2: "LONDON",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
    ]

    Helper::NaturalSort.sort!(addresses)

    expect(addresses).to eq(
    [
      {
        address_line1: "9 WALWORTH ROAD",
        address_line2: "LONDON",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "10 WALWORTH ROAD",
        address_line2: "LONDON",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "10 WALWORTH ROAD",
        address_line2: "LONDON",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
    ]
   )
  end

  it "can sort addresses when the same address with flats appears twice" do
    addresses = [
      {
        address_line1: "APARTMENT 1",
        address_line2: "10 WALWORTH ROAD",
        address_line3: "LONDON",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "APARTMENT 192",
        address_line2: "9 WALWORTH ROAD",
        address_line3: "LONDON",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "APARTMENT 192",
        address_line2: "9 WALWORTH ROAD",
        address_line3: "LONDON",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
    ]

    Helper::NaturalSort.sort!(addresses)

    expect(addresses).to eq(
     [
       {
         address_line1: "APARTMENT 192",
         address_line2: "9 WALWORTH ROAD",
         address_line3: "LONDON",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "APARTMENT 192",
         address_line2: "9 WALWORTH ROAD",
         address_line3: "LONDON",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "APARTMENT 1",
         address_line2: "10 WALWORTH ROAD",
         address_line3: "LONDON",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
     ]
   )
  end

  it "can sort addresses when the same address that is non-numbered appears twice" do
    addresses = [
      {
        address_line1: "THE BARN",
        address_line2: "LONDON",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "9 WALWORTH ROAD",
        address_line2: "LONDON",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "THE BARN",
        address_line2: "LONDON",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
    ]

    Helper::NaturalSort.sort!(addresses)

    expect(addresses).to eq(
      [
       {
         address_line1: "THE BARN",
         address_line2: "LONDON",
         address_line3: "",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "THE BARN",
         address_line2: "LONDON",
         address_line3: "",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "9 WALWORTH ROAD",
         address_line2: "LONDON",
         address_line3: "",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
     ]
   )
  end

  it "can sort addresses when the flat identifier is a letter and not a number" do
    addresses = [
      {
        address_line1: "Flat B",
        address_line2: "246, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "Flat A",
        address_line2: "246, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "Flat 22",
        address_line2: "244, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "Flat 1",
        address_line2: "244, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
    ]

      Helper::NaturalSort.sort!(addresses)

      expect(addresses).to eq(
       [
         {
           address_line1: "Flat 1",
           address_line2: "244, Walworth Road",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "SE1 6EJ",
         },
         {
           address_line1: "Flat 22",
           address_line2: "244, Walworth Road",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "SE1 6EJ",
         },
         {
           address_line1: "Flat A",
           address_line2: "246, Walworth Road",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "SE1 6EJ",
         },
         {
           address_line1: "Flat B",
           address_line2: "246, Walworth Road",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "SE1 6EJ",
         },
     ]
   )
  end

  it "can sort addresses when the property number contains hyphens" do
    addresses = [
      {
        address_line1: "Flat 2",
        address_line2: "220-222, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "221, Walworth Road",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "Flat 1",
        address_line2: "220-222, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "220, Walworth Road",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "Flat 10",
        address_line2: "225, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
    ]

    Helper::NaturalSort.sort!(addresses)

    expect(addresses).to eq(
     [
       {
         address_line1: "220, Walworth Road",
         address_line2: "",
         address_line3: "",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "Flat 1",
         address_line2: "220-222, Walworth Road",
         address_line3: "",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "Flat 2",
         address_line2: "220-222, Walworth Road",
         address_line3: "",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "221, Walworth Road",
         address_line2: "",
         address_line3: "",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "Flat 10",
         address_line2: "225, Walworth Road",
         address_line3: "",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
     ]
   )
  end

  it "can sort addresses of the same property number with flats containing letters and numbers" do
    addresses = [
      {
        address_line1: "Flat 11",
        address_line2: "100, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "ABC 123",
      },
      {
        address_line1: "Flat A",
        address_line2: "100, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "ABC 123",
      },
      {
        address_line1: "Flat 10",
        address_line2: "100, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "ABC 123",
      },
      {
        address_line1: "Flat B",
        address_line2: "100, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "ABC 123",
      },
    ]

    Helper::NaturalSort.sort!(addresses)

    expect(addresses).to eq(
     [
       {
         address_line1: "Flat A",
         address_line2: "100, Walworth Road",
         address_line3: "",
         address_line4: "",
         town: "LONDON",
         postcode: "ABC 123",
       },
       {
         address_line1: "Flat B",
         address_line2: "100, Walworth Road",
         address_line3: "",
         address_line4: "",
         town: "LONDON",
         postcode: "ABC 123",
       },
       {
         address_line1: "Flat 10",
         address_line2: "100, Walworth Road",
         address_line3: "",
         address_line4: "",
         town: "LONDON",
         postcode: "ABC 123",
       },
       {
         address_line1: "Flat 11",
         address_line2: "100, Walworth Road",
         address_line3: "",
         address_line4: "",
         town: "LONDON",
         postcode: "ABC 123",
       },
     ]
   )
  end

  it "can sort  where address_line one has been left nil" do
    addresses = [
      {
        address_line1: "55, Main Street",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: nil,
        address_line2: "55, Main Street",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "56, Main Street",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "",
        address_line2: "56, Main Street",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
    ]
    Helper::NaturalSort.sort!(addresses)
    expect(addresses).to eq(
     [
       {
         address_line1: nil,
         address_line2: "55, Main Street",
         address_line3: "",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "55, Main Street",
         address_line2: "",
         address_line3: "",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "",
         address_line2: "56, Main Street",
         address_line3: "",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
       {
         address_line1: "56, Main Street",
         address_line2: "",
         address_line3: "",
         address_line4: "",
         town: "LONDON",
         postcode: "SE1 6EJ",
       },
     ]
   )
  end

  it "can sort addresses of a variety of address formats" do
    addresses = [
      {
        address_line1: "55, Main Street",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "55, Main Street",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "ABC 123",
      },
      {
        address_line1: "56, Main Street",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "56c, Main Street",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "56a, Main Street",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "56, Main Street",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "Flat 11",
        address_line2: "225, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "Flat 10",
        address_line2: "225, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "Flat 10",
        address_line2: "224, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "Flat 10",
        address_line2: "100, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "ABC 123",
      },
      {
        address_line1: "Flat A",
        address_line2: "100, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "ABC 123",
      },
      {
        address_line1: "Flat 11",
        address_line2: "100-110, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "ABC 123",
      },
      {
        address_line1: "Flat 15",
        address_line2: "120-130, Walworth Road",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "THE BARN",
        address_line2: "LONDON",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "Atrium",
        address_line2: "LONDON",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },
      {
        address_line1: "The Cottage",
        address_line2: "LONDON",
        address_line3: "",
        address_line4: "",
        town: "LONDON",
        postcode: "SE1 6EJ",
      },

    ]

    Helper::NaturalSort.sort!(addresses)

    expect(addresses).to eq(
       [
         {
           address_line1: "55, Main Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "ABC 123",
         },
         {
           address_line1: "Flat A",
           address_line2: "100, Walworth Road",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "ABC 123",
         },
         {
           address_line1: "Flat 10",
           address_line2: "100, Walworth Road",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "ABC 123",
         },
         {
           address_line1: "Flat 11",
           address_line2: "100-110, Walworth Road",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "ABC 123",
         },
         {
           address_line1: "Atrium",
           address_line2: "LONDON",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "SE1 6EJ",
         },
         {
           address_line1: "THE BARN",
           address_line2: "LONDON",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "SE1 6EJ",
         },
         {
           address_line1: "The Cottage",
           address_line2: "LONDON",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "SE1 6EJ",
         },
         {
           address_line1: "55, Main Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "SE1 6EJ",
         },
         {
           address_line1: "56, Main Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "SE1 6EJ",
         },
         {
           address_line1: "56, Main Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "SE1 6EJ",
         },
         {
           address_line1: "56a, Main Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "SE1 6EJ",
         },
         {
           address_line1: "56c, Main Street",
           address_line2: "",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "SE1 6EJ",
         },
         {
           address_line1: "Flat 15",
           address_line2: "120-130, Walworth Road",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "SE1 6EJ",
         },
         {
           address_line1: "Flat 10",
           address_line2: "224, Walworth Road",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "SE1 6EJ",
         },
         {
           address_line1: "Flat 10",
           address_line2: "225, Walworth Road",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "SE1 6EJ",
         },
         {
           address_line1: "Flat 11",
           address_line2: "225, Walworth Road",
           address_line3: "",
           address_line4: "",
           town: "LONDON",
           postcode: "SE1 6EJ",
         },
       ]
     )
  end
end
