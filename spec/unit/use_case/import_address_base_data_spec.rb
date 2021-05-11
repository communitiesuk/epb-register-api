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
      LAST_UP_DATE
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
      "('100023336956', 'SW1A 2AA', '10 DOWNING STREET', 'LONDON', NULL, NULL, 'LONDON')"
    use_case = UseCase::ImportAddressBaseData.new
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
    use_case = UseCase::ImportAddressBaseData.new
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
      use_case = UseCase::ImportAddressBaseData.new
      imported_address =
        use_case.create_delivery_point_address(Hash[headers.zip(number_ten)])
      expect(imported_address.uprn).to eq expected.uprn
      expect(imported_address.postcode).to eq expected.postcode
      expect(imported_address.lines).to eq expected.lines
      expect(imported_address.town).to eq expected.town
    end
  end

  context "when importing the data for a residential property" do
    use_case = UseCase::ImportAddressBaseData.new
    hashed_data = Hash[headers.zip(number_ten)]
    it "returns a delivery point address" do
      expect(use_case).to receive(:create_delivery_point_address).and_call_original
      use_case.execute(hashed_data)
    end
  end

  context "when importing the data for a commercial property" do
    use_case = UseCase::ImportAddressBaseData.new
    number_ten[5] = "C"
    hashed_data = Hash[headers.zip(number_ten)]
    it "returns a geographic address" do
      expect(use_case).to receive(:create_geographic_address).and_call_original
      use_case.execute(hashed_data)
    end
  end

  context "when attempting to create a postal address for a residential house in devon with no postal address" do
    devon_house = ["10023353973",nil,"I",3,2016-01-15,"RD06",10002296559,227014.30,102933.65,50.8000700,-4.4561946,2,1145,"E","2010-07-22","2019-04-28","2010-07-20","","","","","","",nil,nil,"",nil,"","ANNEXE","",nil,"",nil,"","AGENA","",40902264,"1","","","N","",nil,"osgb4000000020915444",8,"osgb1000021646431",3,235095000,nil,"ROAD FROM JEWELLS CROSS TO LITTLE BRIDGE CROSS","","","","","","","","","","","BRIDGERULE","DEVON","","","","EX22 7EX","","","C","","E05011925","E04003251",nil,0,"","",""]
    use_case = UseCase::ImportAddressBaseData.new
    hashed_data = Hash[headers.zip(devon_house)]
    it "returns a geographic address" do
      expected = "('10023353973', 'EX22 7EX', 'ANNEXE', 'AGENA', 'ROAD FROM JEWELLS CROSS TO LITTLE BRIDGE CROSS', 'BRIDGERULE', 'BRIDGERULE')"
      partial_clause = use_case.execute(hashed_data)
      expect(partial_clause).to eq expected
    end
    it "raises an error when trying to create a postal address" do
      expect{use_case.create_delivery_point_address(hashed_data)}.to raise_error(ArgumentError)
    end
  end

  context "when forming a delivery point address with a lettered street number" do
    lettered_number_address = ["90090877","7645063","I",2,"2007-10-09","RD04",nil,394096.94,288199.29,52.4916876,-2.0883638,1,4615,"E","2008-01-03","2020-06-13","2001-02-12","","","","","","8A",nil,nil,"",nil,"","","",8,"A",nil,"","","",11400396,"1","","","Y","osgb1000002247769942",8,"osgb4000000017856380",5,"osgb1000019544958",4,72803239,nil,"HILL STREET","","","HILL STREET","","","","NETHERTON","","","","NETHERTON","DUDLEY","DUDLEY","","DY2 0NZ","DY2 0NZ","S","2T","D","","E05001250","","2012-03-19",0,"","",""];
    use_case = UseCase::ImportAddressBaseData.new
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
      imported_address = use_case.create_delivery_point_address(hashed_data)
      expect(imported_address.uprn).to eq expected.uprn
      expect(imported_address.postcode).to eq expected.postcode
      expect(imported_address.lines).to eq expected.lines
      expect(imported_address.town).to eq expected.town
    end
  end
end
