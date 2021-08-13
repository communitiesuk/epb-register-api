describe UseCase::ImportAddressBaseData do
  headers =
    %w[
      UPRN
      UDPRN
      CHANGE_TYPE
      STATE
      STATE_DATE
      CLASS
      PARENT_UPRN
      X_COORDINATE
      Y_COORDINATE
      LATITUDE
      LONGITUDE
      RPC
      LOCAL_CUSTODIAN_CODE
      COUNTRY
      LA_START_DATE
      LAST_UPDATE_DATE
      ENTRY_DATE
      RM_ORGANISATION_NAME
      LA_ORGANISATION
      DEPARTMENT_NAME
      LEGAL_NAME
      SUB_BUILDING_NAME
      BUILDING_NAME
      BUILDING_NUMBER
      SAO_START_NUMBER
      SAO_START_SUFFIX
      SAO_END_NUMBER
      SAO_END_SUFFIX
      SAO_TEXT
      ALT_LANGUAGE_SAO_TEXT
      PAO_START_NUMBER
      PAO_START_SUFFIX
      PAO_END_NUMBER
      PAO_END_SUFFIX
      PAO_TEXT
      ALT_LANGUAGE_PAO_TEXT
      USRN
      USRN_MATCH_INDICATOR
      AREA_NAME
      LEVEL
      OFFICIAL_FLAG
      OS_ADDRESS_TOID
      OS_ADDRESS_TOID_VERSION
      OS_ROADLINK_TOID
      OS_ROADLINK_TOID_VERSION
      OS_TOPO_TOID
      OS_TOPO_TOID_VERSION
      VOA_CT_RECORD
      VOA_NDR_RECORD
      STREET_DESCRIPTION
      ALT_LANGUAGE_STREET_DESCRIPTION
      DEPENDENT_THOROUGHFARE
      THOROUGHFARE
      WELSH_DEPENDENT_THOROUGHFARE
      WELSH_THOROUGHFARE
      DOUBLE_DEPENDENT_LOCALITY
      DEPENDENT_LOCALITY
      LOCALITY
      WELSH_DEPENDENT_LOCALITY
      WELSH_DOUBLE_DEPENDENT_LOCALITY
      TOWN_NAME
      ADMINISTRATIVE_AREA
      POST_TOWN
      WELSH_POST_TOWN
      POSTCODE
      POSTCODE_LOCATOR
      POSTCODE_TYPE
      DELIVERY_POINT_SUFFIX
      ADDRESSBASE_POSTAL
      PO_BOX_NUMBER
      WARD_CODE
      PARISH_CODE
      RM_START_DATE
      MULTI_OCC_COUNT
      VOA_NDR_P_DESC_CODE
      VOA_NDR_SCAT_CODE
      ALT_LANGUAGE
    ].map(&:to_sym)
  number_ten = [
    "100023336956",
    23_747_771,
    "I",
    2,
    "2001-03-19",
    "RD04",
    nil,
    530_047.00,
    179_951.00,
    51.5035410,
    -0.1276700,
    2,
    5990,
    "E",
    "2007-12-28",
    "2020-05-02",
    "2001-03-19",
    "PRIME MINISTER & FIRST LORD OF THE TREASURY",
    "",
    "",
    "",
    "",
    "",
    10,
    nil,
    "",
    nil,
    "",
    "",
    "",
    10,
    "",
    nil,
    "",
    "",
    "",
    8_400_071,
    "1",
    "",
    "",
    "",
    "osgb1000002148079385",
    7,
    "osgb5000005158744708",
    1,
    "osgb1000005572568",
    6,
    186_814_088,
    nil,
    "DOWNING STREET",
    "",
    "",
    "DOWNING STREET",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "LONDON",
    "CITY OF WESTMINSTER",
    "LONDON",
    "",
    "SW1A 2AA",
    "SW1A 2AA",
    "L",
    "1A",
    "D",
    "",
    "E05000644",
    "",
    "2012-03-19",
    1,
    "",
    "",
    "",
  ]
  context "when importing the data for 10 downing street" do
    expected_query_clause =
      "('100023336956', 'SW1A 2AA', '10 DOWNING STREET', NULL, NULL, NULL, 'LONDON', 'RD04', 'Delivery Point')"
    use_case = described_class.new
    it "creates a query clause in the expected form" do
      hashed_data = Hash[headers.zip(number_ten)]
      expect(use_case.execute(hashed_data)).to eq expected_query_clause
    end
  end

  context "when importing the data for a pond in nottinghamshire" do
    pond = [
      "10025731071",
      nil,
      "I",
      nil,
      nil,
      "LW02IW",
      nil,
      497_657.18,
      319_960.70,
      52.7684428,
      -0.5539914,
      1,
      7655,
      "E",
      "2018-11-29",
      "2019-06-02",
      "2018-11-27",
      "",
      "",
      "2018-11-27",
      "",
      "",
      "",
      "",
      "",
      "",
      nil,
      nil,
      "",
      nil,
      "",
      "",
      "",
      nil,
      "",
      nil,
      "",
      "CENTRE OF POND 238M FROM KAAIMANS INTERNATIONAL, UNIT 4, TOLLERTON HALL 254M FROM UNNAMED",
      "",
      33_002_303,
      "2",
      "",
      "",
      "N",
      "",
      nil,
      "osgb5000005220644080",
      1,
      "osgb1000002083774996",
      5,
      nil,
      nil,
      "TOLLERTON LANE",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "TOLLERTON",
      "NOTTINGHAMSHIRE",
      "",
      "",
      "",
      "NG12 4GQ",
      "",
      "",
      "N",
      "",
      "E05009731",
      "E04008010",
      nil,
      0,
      "",
      "",
      "",
    ]
    use_case = described_class.new
    it "responds with nil because ponds are not certifiable" do
      hashed_data = Hash[headers.zip(pond)]
      expect(use_case.execute(hashed_data)).to be nil
    end
  end

  context "when forming a delivery point address for 10 downing street" do
    it "responds with an address struct with the expected fields" do
      expected =
        OpenStruct.new(
          {
            uprn: "100023336956",
            postcode: "SW1A 2AA",
            lines: ["10 DOWNING STREET"],
            town: "LONDON",
          },
        )
      use_case = described_class.new
      imported_address =
        use_case.send(
          :create_delivery_point_address,
          Hash[headers.zip(number_ten)],
        )
      expect(imported_address.uprn).to eq expected.uprn
      expect(imported_address.postcode).to eq expected.postcode
      expect(imported_address.lines).to eq expected.lines
      expect(imported_address.town).to eq expected.town
    end
  end

  context "when importing the data for a residential property" do
    use_case = described_class.new
    hashed_data = Hash[headers.zip(number_ten)]
    it "returns a delivery point address" do
      expect(use_case).to receive(:create_delivery_point_address)
        .and_call_original
      use_case.execute(hashed_data)
    end
  end

  context "when importing the data for a commercial property" do
    use_case = described_class.new
    commercial_number_ten = number_ten.clone
    commercial_number_ten[5] = "C"
    hashed_data = Hash[headers.zip(commercial_number_ten)]
    it "returns a geographic address" do
      expect(use_case).to receive(:create_geographic_address).and_call_original
      use_case.execute(hashed_data)
    end
  end

  context "when attempting to create a postal address for a residential house in devon with no postal address" do
    devon_house = [
      "10023353973",
      nil,
      "I",
      3,
      2016 - 0o1 - 15,
      "RD06",
      10_002_296_559,
      227_014.30,
      102_933.65,
      50.8000700,
      -4.4561946,
      2,
      1145,
      "E",
      "2010-07-22",
      "2019-04-28",
      "2010-07-20",
      "",
      "",
      "",
      "",
      "",
      "",
      nil,
      nil,
      "",
      nil,
      "",
      "ANNEXE",
      "",
      nil,
      "",
      nil,
      "",
      "AGENA",
      "",
      40_902_264,
      "1",
      "",
      "",
      "N",
      "",
      nil,
      "osgb4000000020915444",
      8,
      "osgb1000021646431",
      3,
      235_095_000,
      nil,
      "ROAD FROM JEWELLS CROSS TO LITTLE BRIDGE CROSS",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "BRIDGERULE",
      "DEVON",
      "",
      "",
      "",
      "EX22 7EX",
      "",
      "",
      "C",
      "",
      "E05011925",
      "E04003251",
      nil,
      0,
      "",
      "",
      "",
    ]
    use_case = described_class.new
    hashed_data = Hash[headers.zip(devon_house)]
    it "returns a geographic address" do
      expected =
        "('10023353973', 'EX22 7EX', 'ANNEXE', 'AGENA', 'ROAD FROM JEWELLS CROSS TO LITTLE BRIDGE CROSS', NULL, 'BRIDGERULE', 'RD06', 'Geographic')"
      partial_clause = use_case.execute(hashed_data)
      expect(partial_clause).to eq expected
    end

    it "raises an error when trying to create a postal address" do
      expect {
        use_case.send(:create_delivery_point_address, hashed_data)
      }.to raise_error(ArgumentError)
    end
  end

  context "when forming a delivery point address with a lettered street number" do
    lettered_number_address = [
      "90090877",
      "7645063",
      "I",
      2,
      "2007-10-09",
      "RD04",
      nil,
      394_096.94,
      288_199.29,
      52.4916876,
      -2.0883638,
      1,
      4615,
      "E",
      "2008-01-03",
      "2020-06-13",
      "2001-02-12",
      "",
      "",
      "",
      "",
      "",
      "8A",
      nil,
      nil,
      "",
      nil,
      "",
      "",
      "",
      8,
      "A",
      nil,
      "",
      "",
      "",
      11_400_396,
      "1",
      "",
      "",
      "Y",
      "osgb1000002247769942",
      8,
      "osgb4000000017856380",
      5,
      "osgb1000019544958",
      4,
      72_803_239,
      nil,
      "HILL STREET",
      "",
      "",
      "HILL STREET",
      "",
      "",
      "",
      "NETHERTON",
      "",
      "",
      "",
      "NETHERTON",
      "DUDLEY",
      "DUDLEY",
      "",
      "DY2 0NZ",
      "DY2 0NZ",
      "S",
      "2T",
      "D",
      "",
      "E05001250",
      "",
      "2012-03-19",
      0,
      "",
      "",
      "",
    ]
    use_case = described_class.new
    hashed_data = Hash[headers.zip(lettered_number_address)]
    it "joins the lettered number line onto the following non-empty line" do
      expected =
        OpenStruct.new(
          {
            uprn: "90090877",
            postcode: "DY2 0NZ",
            lines: ["8A HILL STREET", "NETHERTON"],
            town: "DUDLEY",
          },
        )
      imported_address =
        use_case.send(:create_delivery_point_address, hashed_data)
      expect(imported_address.uprn).to eq expected.uprn
      expect(imported_address.postcode).to eq expected.postcode
      expect(imported_address.lines).to eq expected.lines
      expect(imported_address.town).to eq expected.town
    end
  end

  context "when given a commercial address with duplicate locality information" do
    rhyl_address = [
      "100100946350",
      "13523952",
      "I",
      2,
      "2009-03-19",
      "CR02",
      100_101_059_525,
      300_819.00,
      381_603.00,
      53.3220443,
      -3.4904488,
      2,
      6830,
      "W",
      "2008-02-27",
      "2020-06-13",
      "2003-02-17",
      "THOMSONS",
      "TUI",
      "",
      "",
      "",
      "UNIT 10",
      nil,
      nil,
      "",
      nil,
      "",
      "UNIT 10",
      "UNIT 10",
      nil,
      "",
      nil,
      "",
      "WHITE ROSE CENTRE",
      "WHITE ROSE CENTRE",
      46_700_583,
      "1",
      "",
      "",
      "N",
      "osgb1000002166013658",
      14,
      "osgb5000005161922234",
      0,
      "osgb1000034315691",
      5,
      nil,
      262_386_206,
      "HIGH STREET",
      "Y STRYD FAWR",
      "WHITE ROSE CENTRE",
      "HIGH STREET",
      "CANOLFAN Y RHOSYN GWYN",
      "STRYD FAWR",
      "",
      "",
      "",
      "",
      "",
      "RHYL",
      "DENBIGHSHIRE",
      "RHYL",
      "Y RHYL",
      "LL18 1EW",
      "LL18 1EW",
      "S",
      "2H",
      "D",
      "",
      "W05000174",
      "W04000173",
      "2012-03-19",
      0,
      "CS",
      "249",
      "CYM",
    ]
    use_case = described_class.new
    hashed_data = Hash[headers.zip(rhyl_address)]
    it "removes the duplicate line" do
      expected =
        OpenStruct.new(
          {
            uprn: "100100946350",
            postcode: "LL18 1EW",
            lines: ["UNIT 10", "WHITE ROSE CENTRE", "HIGH STREET"],
            town: "RHYL",
          },
        )
      imported_address = use_case.send(:create_geographic_address, hashed_data)
      expect(imported_address.uprn).to eq expected.uprn
      expect(imported_address.postcode).to eq expected.postcode
      expect(imported_address.lines).to eq expected.lines
      expect(imported_address.town).to eq expected.town
    end
  end

  context "given a line of address data that forms more than four street lines in a delivery point address" do
    place_in_cheam = [
      "5870116854",
      "50537552",
      "I",
      2,
      "2007-10-10",
      "RD06",
      "5870117894",
      524_095.00,
      163_531.00,
      51.3573056,
      -0.2191271,
      2,
      5870,
      "E",
      "2007-12-13",
      "2018-09-23",
      "2006-11-22",
      "",
      "",
      "",
      "",
      "FLAT 12",
      "WELLS COURT",
      nil,
      12,
      "",
      nil,
      "",
      "",
      "",
      nil,
      "",
      nil,
      "",
      "WELLS COURT",
      "",
      22_605_929,
      "1",
      "",
      "",
      "",
      "osgb1000002230091572",
      5,
      "osgb5000005205514380",
      1,
      "osgb1000001799485796",
      4,
      5_960_011_000,
      nil,
      "KILLICK MEWS",
      "",
      "KILLICK MEWS",
      "EWELL ROAD",
      "",
      "",
      "",
      "CHEAM",
      "",
      "",
      "",
      "CHEAM",
      "SUTTON",
      "SUTTON",
      "",
      "SM3 8AR",
      "SM3 8AR",
      "S",
      "1Z",
      "D",
      "",
      "E05000560",
      "",
      "2012-03-19",
      0,
      "",
      "",
      "",
    ]
    use_case = described_class.new
    hashed_data = Hash[headers.zip(place_in_cheam)]
    it "compacts all lines after line 4 onto one line separated by commas" do
      expected =
        OpenStruct.new(
          uprn: "5870116854",
          postcode: "SM3 8AR",
          lines: [
            "FLAT 12",
            "WELLS COURT",
            "KILLICK MEWS",
            "EWELL ROAD, CHEAM",
          ],
          town: "SUTTON",
        )
      imported_address =
        use_case.send(:create_delivery_point_address, hashed_data)
      expect(imported_address.uprn).to eq expected.uprn
      expect(imported_address.postcode).to eq expected.postcode
      expect(imported_address.lines).to eq expected.lines
      expect(imported_address.town).to eq expected.town
    end
  end
end
