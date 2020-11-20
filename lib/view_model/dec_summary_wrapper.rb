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
      when "CEPC-6.0"
        @view_model = ViewModel::Cepc60::Dec.new xml
      else
        raise ArgumentError, "Unsupported schema type"
      end
    end

    def type
      :DEC
    end

    def to_xml
      xml = <<~XML
        <Reports
          xmlns="https://epbr.digital.communities.gov.uk/xsd/dec-summary"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="https://epbr.digital.communities.gov.uk/xsd/dec-summary  ../../../../api/schemas/xml/CEPC-8.0.0/DEC-Summary.xsd"
        >
          <Report>
            <Report-Header>
              <Report-Type>#{@view_model.report_type}</Report-Type>
              <Property-Details>
                <UPRN>#{
                  if @view_model.address_id.include?('LPRN-')
                    ''
                  else
                    @view_model.address_id
                  end
                }</UPRN>
              </Property-Details>
              <Calculation-Details>
                <Output-Engine>#{@view_model.output_engine}</Output-Engine>
              </Calculation-Details>
            </Report-Header>
            <OR-Operational-Rating>
              <OR-Assessment-Start-Date>#{
                @view_model.or_assessment_start_date
              }</OR-Assessment-Start-Date>
              <OR-Assessment-End-Date>#{
                @view_model.or_assessment_end_date
              }</OR-Assessment-End-Date>
              <OR-Benchmark-Data>
                <Benchmarks>#{
                  get_benchmark_xml(@view_model.benchmarks)
                }</Benchmarks>
              </OR-Benchmark-Data>
              <OR-Energy-Consumption>#{
                get_or_energy_consumption_xml(@view_model.or_energy_consumption)
              }</OR-Energy-Consumption>
            </OR-Operational-Rating>
            <Display-Certificate>
              <DEC-Annual-Energy-Summary>
                <Annual-Energy-Use-Electrical>#{
                  @view_model.annual_energy_summary[:electrical]
                }</Annual-Energy-Use-Electrical>
                <Annual-Energy-Use-Fuel-Thermal>#{
                  @view_model.annual_energy_summary[:fuel_thermal]
                }</Annual-Energy-Use-Fuel-Thermal>
                <Renewables-Fuel-Thermal>#{
                  @view_model.annual_energy_summary[:renewables_fuel_thermal]
                }</Renewables-Fuel-Thermal>
                <Renewables-Electrical>#{
                  @view_model.annual_energy_summary[:renewables_electrical]
                }</Renewables-Electrical>
                <Typical-Thermal-Use>#{
                  @view_model.annual_energy_summary[:typical_thermal_use]
                }</Typical-Thermal-Use>
                <Typical-Electrical-Use>#{
                  @view_model.annual_energy_summary[:typical_electrical_use]
                }</Typical-Electrical-Use>
              </DEC-Annual-Energy-Summary>
              <DEC-Status>#{@view_model.dec_status}</DEC-Status>
              <This-Assessment>
                <Nominated-Date>#{
                  @view_model.current_assessment_date
                }</Nominated-Date>
                <Energy-Rating>#{
                  @view_model.energy_efficiency_rating
                }</Energy-Rating>
                <Electricity-CO2>#{
                  @view_model.current_electricity_co2
                }</Electricity-CO2>
                <Heating-CO2>#{
                  @view_model.current_heating_co2
                }</Heating-CO2>
                <Renewables-CO2>#{
                  @view_model.current_renewables_co2
                }</Renewables-CO2>
              </This-Assessment>
              <Technical-Information>
                <Main-Heating-Fuel>#{
                  @view_model.main_heating_fuel
                }</Main-Heating-Fuel>
              </Technical-Information>
            </Display-Certificate>
          </Report>
        </Reports>
      XML

      if @view_model.dec_status.nil?
        doc = Nokogiri.XML(xml)
        doc.at('DEC-Status').remove
        xml = doc.to_xml
      end
      xml
    end

    def get_view_model
      @view_model
    end

    def get_benchmark_xml(data)
      "\n" +
        data.map { |benchmark|
          <<-XML
          <Benchmark>
            <Name>#{benchmark[:name]}</Name>
            <Benchmark-ID>#{benchmark[:id]}</Benchmark-ID>
            <TUFA>#{benchmark[:tufa]}</TUFA>
          </Benchmark>
          XML
        }.join + "        "
    end

    def get_or_energy_consumption_xml(data)
      "\n" +
        data.map { |energy_consumption|
          next if energy_consumption[:start_date].blank?

          <<-XML
        <#{energy_consumption[:name]}>
          <Consumption>#{energy_consumption[:consumption]}</Consumption>
          <Start-Date>#{energy_consumption[:start_date]}</Start-Date>
          <End-Date>#{energy_consumption[:end_date]}</End-Date>
          <Estimate>#{energy_consumption[:estimate]}</Estimate>
        </#{energy_consumption[:name]}>
          XML
        }.join + "      "
    end
  end
end
