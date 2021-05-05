describe UseCase::ImportAddressBaseData do
  context "when importing the data for 10 downing street" do
    number_ten = ["100023336956",23747771,"I",2,"2001-03-19","RD04",nil,530047.00,179951.00,51.5035410,-0.1276700,2,5990,"E","2007-12-28","2020-05-02","2001-03-19","PRIME MINISTER & FIRST LORD OF THE TREASURY","","","","","",10,nil,"",nil,"","","",10,"",nil,"","","",8400071,"1","","","","osgb1000002148079385",7,"osgb5000005158744708",1,"osgb1000005572568",6,186814088,nil,"DOWNING STREET","","","DOWNING STREET","","","","","","","","LONDON","CITY OF WESTMINSTER","LONDON","","SW1A 2AA","SW1A 2AA","L","1A","D","","E05000644","","2012-03-19",1,"","",""]
    expected_query_clause = "('100023336956', 'SW1A 2AA', '10 DOWNING STREET', 'LONDON', NULL, NULL, 'LONDON')"
    use_case = UseCase::ImportAddressBaseData.new
    it "creates a query clause in the expected form" do
      expect(use_case.execute(number_ten)). to eq expected_query_clause
    end
  end

  context "when importing the data for a pond in nottinghamshire" do
    pond = ["10025731071",nil,"I",nil,nil,"LW02IW",nil,497657.18,319960.70,52.7684428,-0.5539914,1,7655,"E","2018-11-29","2019-06-02","2018-11-27","","","2018-11-27","","","","","","",nil,nil,"",nil,"","","",nil,"",nil,"","CENTRE OF POND 238M FROM KAAIMANS INTERNATIONAL, UNIT 4, TOLLERTON HALL 254M FROM UNNAMED","",33002303,"2","","","N","",nil,"osgb5000005220644080",1,"osgb1000002083774996",5,nil,nil,"TOLLERTON LANE","","","","","","","","","","","TOLLERTON","NOTTINGHAMSHIRE","","","","NG12 4GQ","","","N","","E05009731","E04008010",nil,0,"","",""]
    use_case = UseCase::ImportAddressBaseData.new
    it "responds with nil because ponds are not certifiable" do
      expect(use_case.execute(pond)).to be nil
    end
  end
end
