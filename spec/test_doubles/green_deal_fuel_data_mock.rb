class GreenDealFuelDataMock
  def initialize
    mock_data <<~DATA
      $001,462,2020,06,26
      #
      #
      $191,292,34,2020,06,19,2
      # Table 191 (Current Fuel Prices) follows ...
      # dbv 4.09
      #
      1,1,91,3.95,2020/Jun/19 12:00
      2,4,0,4.61,2020/Jun/19 12:00
      3,21,0,3.57,2020/Jun/19 12:00
      4,40,0,11.20,2020/Jun/19 12:00
      #
      # ... end of Table 191 Format 292
      #
    DATA
  end

  def mock_data(data)
    WebMock.enable!

    WebMock.stub_request(:get, "http://www.boilers.org.uk/data1/pcdf2012.dat")
      .to_return(status: 200, body: data)
  end

  def disable
    WebMock.disable!
  end
end
