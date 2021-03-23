module ViewModel
  class DecSummaryWrapper
    class AssessmentNotSupported < StandardError
    end
    TYPE_OF_ASSESSMENT = "DEC".freeze

    def initialize(xml, schema_type)
      xml = Nokogiri.XML(xml).remove_namespaces!.to_s

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
        raise AssessmentNotSupported
      end
    end

    def type
      :DEC
    end

    def to_xml
      template = <<~ERB
        <Reports
          xmlns="https://epbr.digital.communities.gov.uk/xsd/dec-summary"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="https://epbr.digital.communities.gov.uk/xsd/dec-summary  ../../../../api/schemas/xml/CEPC-8.0.0/DEC-Summary.xsd"
        >
          <Report>
            <Report-Header>
              <Report-Type><%= report_type %></Report-Type>
              <Property-Details>
                <UPRN><%= address_id %></UPRN>
              </Property-Details>
              <Calculation-Details>
                <Output-Engine><%= output_engine %></Output-Engine>
              </Calculation-Details>
            </Report-Header>
            <OR-Operational-Rating>
              <OR-Assessment-Start-Date><%= assessment_start_date %></OR-Assessment-Start-Date>
              <OR-Assessment-End-Date><%= assessment_end_date %></OR-Assessment-End-Date>
              <OR-Benchmark-Data>
                <Benchmarks><% benchmarks.each do |benchmark| %>
                  <Benchmark>
                    <Name><%= benchmark[:name] %></Name>
                    <Benchmark-ID><%= benchmark[:id] %></Benchmark-ID>
                    <TUFA><%= benchmark[:tufa] %></TUFA>
                  </Benchmark>
                <% end %></Benchmarks>
              </OR-Benchmark-Data>
              <OR-Energy-Consumption><% energy_consumption.each do |consumption| %>
                <<%= consumption[:name] %>>
                  <Consumption><%= consumption[:consumption] %></Consumption>
                  <Start-Date><%= consumption[:start_date] %></Start-Date>
                  <End-Date><%= consumption[:end_date] %></End-Date>
                  <Estimate><%= consumption[:estimate] %></Estimate>
                </<%= consumption[:name] %>><% end %>
              </OR-Energy-Consumption>
            </OR-Operational-Rating>
            <Display-Certificate>
              <DEC-Annual-Energy-Summary>
                <Annual-Energy-Use-Electrical><%= annual_energy_summary[:electrical] %></Annual-Energy-Use-Electrical>
                <Annual-Energy-Use-Fuel-Thermal><%= annual_energy_summary[:fuel_thermal] %></Annual-Energy-Use-Fuel-Thermal>
                <Renewables-Fuel-Thermal><%= annual_energy_summary[:renewables_fuel_thermal] %></Renewables-Fuel-Thermal>
                <Renewables-Electrical><%= annual_energy_summary[:renewables_electrical] %></Renewables-Electrical>
                <Typical-Thermal-Use><%= annual_energy_summary[:typical_thermal_use] %></Typical-Thermal-Use>
                <Typical-Electrical-Use><%= annual_energy_summary[:typical_electrical_use] %></Typical-Electrical-Use>
              </DEC-Annual-Energy-Summary>
              <DEC-Status><%= dec_status %></DEC-Status>
              <This-Assessment>
                <Nominated-Date><%= current_assessment_date %></Nominated-Date>
                <Energy-Rating><%= energy_efficiency_rating %></Energy-Rating>
                <Electricity-CO2><%= current_electricity_co2 %></Electricity-CO2>
                <Heating-CO2><%= current_heating_co2 %></Heating-CO2>
                <Renewables-CO2><%= current_renewables_co2 %></Renewables-CO2>
              </This-Assessment>
              <Technical-Information>
                <Main-Heating-Fuel><%= main_heating_fuel %></Main-Heating-Fuel>
              </Technical-Information>
            </Display-Certificate>
          </Report>
        </Reports>
      ERB

      dec_data = {
        report_type: @view_model.report_type,
        address_id:
          if @view_model.address_id&.include?("LPRN-")
            ""
          else
            @view_model.address_id
          end,
        output_engine: @view_model.output_engine,
        assessment_start_date: @view_model.or_assessment_start_date,
        assessment_end_date: @view_model.or_assessment_end_date,
        benchmarks: @view_model.benchmarks,
        energy_consumption: @view_model.or_energy_consumption,
        annual_energy_summary: @view_model.annual_energy_summary,
        dec_status: @view_model.dec_status,
        current_assessment_date: @view_model.current_assessment_date,
        energy_efficiency_rating: @view_model.energy_efficiency_rating,
        current_electricity_co2: @view_model.current_electricity_co2,
        current_heating_co2: @view_model.current_heating_co2,
        current_renewables_co2: @view_model.current_renewables_co2,
        main_heating_fuel: @view_model.main_heating_fuel,
      }

      xml = ERB.new(template).result_with_hash dec_data

      if @view_model.dec_status.nil?
        doc = Nokogiri.XML(xml)
        doc.at("DEC-Status").remove
        xml = doc.to_xml
      end

      xml
    end

    def get_view_model
      @view_model
    end
  end
end
