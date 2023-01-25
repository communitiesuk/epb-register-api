class GreenDealFuelDataMock
  def initialize
    @mock_data = response_data
  end

  def scan(string_response)
    string_response.scan(/^\d,\d+,\d+,\d+\.\d+,\d{4}\/\S+\/\d+ \d{2}:\d{2}/mi)
  end

  def response_data
    <<~DATA
      $001,462,2020,06,26
      #
      #
      $191,292,34,2020,06,19,2
      # Table 191 (Current Fuel Prices) follows ...
      # dbv 4.09
      #
      1,1,90,3.97,2019/Dec/03 12:12
      1,9,90,3.97,2019/Dec/03 12:12
      1,2,59,6.74,2019/Dec/03 12:12
      1,3,0,10.86,2019/Dec/03 12:12
      1,7,59,6.74,2019/Dec/03 12:12
      2,4,0,4.60,2019/Dec/03 12:12
      2,74,0,4.60,2019/Dec/03 12:12
      2,75,0,5.16,2019/Dec/03 12:12
      2,71,0,6.46,2019/Dec/03 12:12
      2,73,0,6.46,2019/Dec/03 12:12
      2,76,0,47.00,2013/Jun/21 14:36
      3,11,0,4.22,2019/Dec/03 12:12
      3,15,0,4.13,2019/Dec/03 12:12
      3,12,0,5.14,2019/Dec/03 12:12
      3,20,0,4.65,2013/Dec/10 16:52
      3,22,0,6.09,2018/Jun/11 11:43
      3,23,0,5.51,2018/Jun/11 11:43
      3,21,0,3.48,2018/Jun/11 11:43
      3,10,0,4.56,2019/Dec/03 12:12
      4,30,84,18.27,2019/Dec/03 12:12
      4,32,6,21.54,2019/Dec/03 12:12
      4,31,0,8.44,2019/Dec/03 12:12
      4,34,4,19.08,2019/Dec/03 12:12
      4,33,0,10.89,2019/Dec/03 12:12
      4,38,27,16.11,2019/Dec/03 12:12
      4,40,0,10.93,2019/Dec/03 12:12
      4,35,17,10.75,2019/Dec/03 12:12
      4,36,0,18.27,2019/Dec/03 12:12
      5,47,90,4.84,2019/Dec/03 12:12
      6,48,0,3.39,2019/Dec/03 12:12
      #
      # ... end of Table 191 Format 292
      #
    DATA
  end

  def mock_data
    WebMock.enable!
    WebMock
      .stub_request(:get, "https://www.ncm-pcdb.org.uk/pcdb/pcdf2012.dat")
      .to_return(status: 200, body: @mock_data)
  end

  def disable
    WebMock.disable!
  end
end
