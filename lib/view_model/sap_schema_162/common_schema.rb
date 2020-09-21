module ViewModel
  module SapSchema162
    class CommonSchema
      def initialize(xml)
        @xml_doc = Nokogiri.XML xml
      end

      def xpath(queries, node = @xml_doc)
        queries.each do |query|
          if node
            node = node.at query
          else
            return nil
          end
        end
        node ? node.content : nil
      end

      def assessment_id
        xpath(%w[RRN])
      end

      def address_line1
        xpath(%w[Property Address Address-Line-1])
      end

      def address_line2
        xpath(%w[Property Address Address-Line-2]).to_s
      end

      def address_line3
        xpath(%w[Property Address Address-Line-3]).to_s
      end

      def address_line4
        xpath(%w[Property Address Address-Line-4]).to_s
      end

      def town
        xpath(%w[Property Address Post-Town])
      end

      def postcode
        xpath(%w[Property Address Postcode])
      end

      def scheme_assessor_id
        xpath(%w[Certificate-Number])
      end

      def assessor_name
        [
          xpath(%w[Home-Inspector Name Prefix]),
          xpath(%w[Home-Inspector Name First-Name]),
          xpath(%w[Home-Inspector Name Surname]),
          xpath(%w[Home-Inspector Name Suffix]),
        ].reject { |e| e.to_s.empty? }.join(" ")
      end

      def assessor_email
        xpath(%w[Home-Inspector E-Mail])
      end

      def assessor_telephone
        xpath(%w[Home-Inspector Telephone])
      end

      def date_of_assessment
        xpath(%w[Inspection-Date])
      end

      def date_of_registration
        xpath(%w[Registration-Date])
      end

      def address_id
        xpath(%w[UPRN])
      end

      def date_of_expiry
        expires_at = Date.parse(date_of_registration) >> 12 * 10

        expires_at.to_s
      end

      def property_summary
        @xml_doc.search("Energy-Assessment Property-Summary").children.select(
          &:element?
        ).map { |node|
          next if xpath(%w[Energy-Efficiency-Rating], node).nil?

          {
            energy_efficiency_rating:
              xpath(%w[Energy-Efficiency-Rating], node).to_i,
            environmental_efficiency_rating:
              xpath(%w[Environmental-Efficiency-Rating], node).to_i,
            name: node.name.underscore,
            description: xpath(%w[Description], node),
          }
        }.compact
      end

      def related_party_disclosure_text
        xpath(%w[Related-Party-Disclosure-Text])
      end

      def related_party_disclosure_number
        xpath(%w[Related-Party-Disclosure-Number]).to_i
      end

      def improvements
        @xml_doc.search("Suggested-Improvements Improvement").map do |node|
          {
            energy_performance_rating_improvement:
              xpath(%w[Energy-Performance-Rating], node).to_i,
            environmental_impact_rating_improvement:
              xpath(%w[Environmental-Impact-Rating], node).to_i,
            green_deal_category_code: xpath(%w[Green-Deal-Category], node),
            improvement_category: xpath(%w[Improvement-Category], node),
            improvement_code:
              xpath(%w[Improvement-Details Improvement-Number], node),
            improvement_description: xpath(%w[Improvement-Description], node),
            improvement_title: xpath(%w[Improvement-Title], node),
            improvement_type: xpath(%w[Improvement-Type], node),
            indicative_cost: xpath(%w[Indicative-Cost], node),
            sequence: xpath(%w[Sequence], node).to_i,
            typical_saving: xpath(%w[Typical-Saving], node),
          }
        end
      end

      def hot_water_cost_potential
        xpath(%w[Hot-Water-Cost-Potential])
      end

      def heating_cost_potential
        xpath(%w[Heating-Cost-Potential])
      end

      def lighting_cost_potential
        xpath(%w[Lighting-Cost-Potential])
      end

      def hot_water_cost_current
        xpath(%w[Hot-Water-Cost-Current])
      end

      def heating_cost_current
        xpath(%w[Heating-Cost-Current])
      end

      def lighting_cost_current
        xpath(%w[Lighting-Cost-Current])
      end

      def potential_carbon_emission
        convert_to_big_decimal(%w[CO2-Emissions-Potential])
      end

      def current_carbon_emission
        convert_to_big_decimal(%w[CO2-Emissions-Current])
      end

      def potential_energy_rating
        xpath(%w[Energy-Rating-Potential]).to_i
      end

      def current_energy_rating
        xpath(%w[Energy-Rating-Current]).to_i
      end

      def primary_energy_use
        xpath(%w[Energy-Consumption-Current])
      end

      def estimated_energy_cost
        xpath(%w[Estimated-Energy-Cost])
      end

      def total_floor_area
        convert_to_big_decimal(%w[Property-Summary Total-Floor-Area])
      end

      def dwelling_type
        xpath(%w[Dwelling-Type])
      end

      def potential_energy_saving; end

      def property_age_band
        xpath(%w[Construction-Year])
      end

      def tenure
        nil
      end

      def current_space_heating_demand
        convert_to_big_decimal(%w[Space-Heating]) or
          convert_to_big_decimal(%w[Space-Heating-Existing-Dwelling])
      end

      def current_water_heating_demand
        convert_to_big_decimal(%w[Water-Heating])
      end

      def impact_of_cavity_insulation
        if xpath(%w[Impact-Of-Cavity-Insulation])
          xpath(%w[Impact-Of-Cavity-Insulation]).to_i
        end
      end

      def impact_of_loft_insulation
        if xpath(%w[Impact-Of-Loft-Insulation])
          xpath(%w[Impact-Of-Loft-Insulation]).to_i
        end
      end

      def impact_of_solid_wall_insulation
        if xpath(%w[Impact-Of-Solid-Wall-Insulation])
          xpath(%w[Impact-Of-Solid-Wall-Insulation]).to_i
        end
      end

      def status
        date_of_expiry < Time.now ? "EXPIRED" : "ENTERED"
      end

      def type_of_assessment
        case xpath(%w[Report-Type]).to_i
        when 1
          "HCR"
        when 2
          "RdSAP"
        when 3
          "SAP"
        end
      end

    private

      def convert_to_big_decimal(node)
        return unless xpath(node)

        BigDecimal(xpath(node))
      end
    end
  end
end
