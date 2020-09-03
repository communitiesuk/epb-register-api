module ViewModel
  class DecSummaryWrapper
    TYPE_OF_ASSESSMENT = "DEC".freeze

    def initialize(xml, schema_type)
      case schema_type
      when "CEPC-8.0.0"
        @view_model = ViewModel::Cepc800::Dec.new xml
      when "CEPC-NI-8.0.0"
        @view_model = ViewModel::CepcNi800::Dec.new xml
      when "CEPC-7.1"
        @view_model = ViewModel::Cepc71::Dec.new xml
      when "CEPC-7.0"
        @view_model = ViewModel::Cepc70::Dec.new xml
      else
        raise ArgumentError, "Unsupported schema type"
      end
    end

    def type
      :DEC
    end

    def to_xml
      <<~XML
        <Reports
          xmlns="https://epbr.digital.communities.gov.uk/xsd/dec-summary"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="https://epbr.digital.communities.gov.uk/xsd/dec-summary  ../../../../api/schemas/xml/CEPC-8.0.0/DEC-Summary.xsd"
        >
          <Report>
            <Report-Header>
              <Report-Type>#{@view_model.report_type}</Report-Type>
              <Property-Details>
                <UPRN>#{@view_model.address_id}</UPRN>
              </Property-Details>
              <Calculation-Details>
                <Output-Engine>MWW-91.1.1</Output-Engine>
              </Calculation-Details>
            </Report-Header>
            <OR-Operational-Rating>
              <OR-Assessment-Start-Date>2020-05-01</OR-Assessment-Start-Date>
              <OR-Assessment-End-Date>2020-05-01</OR-Assessment-End-Date>
              <OR-Benchmark-Data>
                <Benchmarks>
                  <Benchmark>
                    <Name>Library</Name>
                    <Benchmark-ID>1</Benchmark-ID>
                    <TUFA>1840</TUFA>
                  </Benchmark>
                  <Benchmark>
                    <Name>Offices - cellular, naturally ventilated</Name>
                    <Benchmark-ID>2</Benchmark-ID>
                    <TUFA>682.5</TUFA>
                  </Benchmark>
                  <Benchmark>
                    <Name>Cafe</Name>
                    <Benchmark-ID>3</Benchmark-ID>
                    <TUFA>187</TUFA>
                  </Benchmark>
                </Benchmarks>
              </OR-Benchmark-Data>
              <OR-Energy-Consumption>
                <Electricity>
                  <Consumption>422480</Consumption>
                  <Start-Date>2007-01-31</Start-Date>
                  <End-Date>2008-01-31</End-Date>
                  <Estimate>1</Estimate>
                </Electricity>
                <Gas>
                  <Consumption>310400</Consumption>
                  <Start-Date>2007-01-18</Start-Date>
                  <End-Date>2007-12-18</End-Date>
                  <Estimate>0</Estimate>
                </Gas>
              </OR-Energy-Consumption>
            </OR-Operational-Rating>
            <Display-Certificate>
              <DEC-Annual-Energy-Summary>
                <Annual-Energy-Use-Electrical>156</Annual-Energy-Use-Electrical>
                <Annual-Energy-Use-Fuel-Thermal>129</Annual-Energy-Use-Fuel-Thermal>
                <Renewables-Fuel-Thermal>0</Renewables-Fuel-Thermal>
                <Renewables-Electrical>0</Renewables-Electrical>
                <Typical-Thermal-Use>279</Typical-Thermal-Use>
                <Typical-Electrical-Use>79</Typical-Electrical-Use>
              </DEC-Annual-Energy-Summary>
              <DEC-Status>1</DEC-Status>
              <This-Assessment>
                <Nominated-Date>2020-01-01</Nominated-Date>
                <Energy-Rating>1</Energy-Rating>
                <Electricity-CO2>7</Electricity-CO2>
                <Heating-CO2>3</Heating-CO2>
                <Renewables-CO2>0</Renewables-CO2>
              </This-Assessment>
              <Technical-Information>
                <Main-Heating-Fuel>Natural Gas</Main-Heating-Fuel>
              </Technical-Information>
            </Display-Certificate>
          </Report>
        </Reports>
      XML
    end

    def get_view_model
      @view_model
    end
  end
end
