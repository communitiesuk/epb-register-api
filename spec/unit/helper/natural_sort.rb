describe Helper::NaturalSort do
  it "can sort two addresses" do
    cooked = [
      {
        address_line1: "Flat 33",
        address_line2: "Egality Road",
        address_line3: "",
        address_line4: "",
        town: "",
        postcode: "",
      },
      {
        address_line1: "Flat 101",
        address_line2: "Palmers Road",
        address_line3: "",
        address_line4: "",
        town: "",
        postcode: "",
      },
      {
        address_line1: "Flat 11",
        address_line2: "20 Palmers Road",
        address_line3: "",
        address_line4: "",
        town: "",
        postcode: "",
      },
      {
        address_line1: "Flat 12",
        address_line2: "Johnston Road",
        address_line3: "",
        address_line4: "",
        town: "",
        postcode: "",
      },
      {
        address_line1: "Flat 12",
        address_line2: "Johnston Road",
        address_line3: "",
        address_line4: "",
        town: "London",
        postcode: "",
      },
      {
        address_line1: "Flat 12",
        address_line2: "Johnston Road",
        address_line3: "",
        address_line4: "",
        town: "Aberdeen",
        postcode: "",
      },
    ]

    Helper::NaturalSort.sort!(cooked)

    expect(cooked).to eq(
      [
        {
          address_line1: "Flat 12",
          address_line2: "Johnston Road",
          address_line3: "",
          address_line4: "",
          postcode: "",
          town: "Aberdeen",
        },
        {
          address_line1: "Flat 12",
          address_line2: "Johnston Road",
          address_line3: "",
          address_line4: "",
          postcode: "",
          town: "London",
        },
        {
          address_line1: "Flat 12",
          address_line2: "Johnston Road",
          address_line3: "",
          address_line4: "",
          postcode: "",
          town: "",
        },
        {
          address_line1: "Flat 33",
          address_line2: "Egality Road",
          address_line3: "",
          address_line4: "",
          postcode: "",
          town: "",
        },
        {
          address_line1: "Flat 101",
          address_line2: "Palmers Road",
          address_line3: "",
          address_line4: "",
          postcode: "",
          town: "",
        },
        {
          address_line1: "Flat 11",
          address_line2: "20 Palmers Road",
          address_line3: "",
          address_line4: "",
          postcode: "",
          town: "",
        },
      ],
    )
  end
end
