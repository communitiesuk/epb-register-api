module UseCase
  class FetchDecSummary
    class AssessmentNotFound < StandardError; end
    class AssessmentGone < StandardError; end
    class AssessmentNotDec < StandardError; end

    def initialize
      @assessment_gateway = Gateway::AssessmentsSearchGateway.new
      @assessments_xml_gateway = Gateway::AssessmentsXmlGateway.new
    end

    def execute(assessment_id)
      assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)

      result =
        @assessment_gateway.search_by_assessment_id(assessment_id, false).first

      raise AssessmentNotFound unless result

      if %w[CANCELLED NOT_FOR_ISSUE].include? result.to_hash[:status]
        raise AssessmentGone
      end

      raise AssessmentNotDec if result.to_hash[:type_of_assessment] != "DEC"

      @assessments_xml_gateway.fetch(assessment_id)[:xml]

      master_xml = <<~DEC_SUMMARY
        <Reports
          xmlns="https://epbr.digital.communities.gov.uk/xsd/dec-summary"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="https://epbr.digital.communities.gov.uk/xsd/dec-summary  ../../../../api/schemas/xml/CEPC-8.0.0/DEC-Summary.xsd"
        >
          <Report>
            <Report-Header>
              <Report-Type>1</Report-Type>
              <Property-Details>
                <UPRN>UPRN-365925150000</UPRN>
              </Property-Details>
              <Calculation-Details>
                <Output-Engine>ORGen v3.7.0</Output-Engine>
              </Calculation-Details>
            </Report-Header>
            <OR-Operational-Rating>
              <OR-Assessment-Start-Date>2007-01-18</OR-Assessment-Start-Date>
              <OR-Assessment-End-Date>2008-01-18</OR-Assessment-End-Date>
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
              <DEC-Status>0</DEC-Status>
              <This-Assessment>
                <Nominated-Date>2008-01-18</Nominated-Date>
                <Energy-Rating>114</Energy-Rating>
                <Electricity-CO2>232</Electricity-CO2>
                <Heating-CO2>68</Heating-CO2>
                <Renewables-CO2>0</Renewables-CO2>
              </This-Assessment>
              <Technical-Information>
                <Main-Heating-Fuel>Natural Gas</Main-Heating-Fuel>
              </Technical-Information>
            </Display-Certificate>
          </Report>
        </Reports>
      DEC_SUMMARY

      master_xml
    end
  end
end
