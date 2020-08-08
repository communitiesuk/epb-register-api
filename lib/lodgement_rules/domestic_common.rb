module LodgementRules
  class DomesticCommon
    def self.method_or_nil(adapter, method)
      adapter.send(method)
    rescue NoMethodError
      nil
    end

    RULES = [
      {
        name: "MUST_HAVE_HABITABLE_ROOMS",
        title:
          '"Habitable-Room-Count" must be an integer and must be greater than or equal to 1',
        test: lambda do |adapter|
          habitable_room_count = method_or_nil(adapter, :habitable_room_count)
          if habitable_room_count.nil?
            return true
          end

          begin
            Integer(habitable_room_count) >= 1
          rescue StandardError
            return false
          end
        end,
      },
      {
        name: "RATINGS_MUST_BE_POSITIVE",
        title:
          '"Energy-Rating-Current", "Energy-Rating-Potential", "Environmental-Impact-Current" and "Environmental-Impact-Potential" must be greater than 0',
        test: lambda do |adapter|
          ratings = [
              method_or_nil(adapter, :energy_rating_current),
              method_or_nil(adapter, :energy_rating_potential),
              method_or_nil(adapter, :environmental_impact_current),
              method_or_nil(adapter, :environmental_impact_potential),
          ]
          ratings.compact.map(&:to_i).select {|rating| rating <= 0}.empty?
        end,
      },
      {
        name: "MUST_HAVE_DESCRIPTION",
        title:
          '"Description" for parent node "Wall", "Walls", "Roof", "Floor", "Window", "Windows", "Main-Heating", "Main-Heating-Controls", "Hot-Water", "Lighting" and "Secondary-Heating" must not be equal to the parent node name, ignoring case',
        test: lambda do |adapter|
          walls = method_or_nil(adapter, :all_wall_descriptions)
          unless walls.nil?
            unless walls.compact
              .select { |desc| desc.downcase == "wall" }.empty?
              return false
            end
          end
          roofs = method_or_nil(adapter, :all_roof_descriptions)
          unless roofs.nil?
            unless roofs.compact
              .select { |desc| desc.downcase == "roof" }.empty?
              return false
            end
          end
          floors = method_or_nil(adapter, :all_floor_descriptions)
          unless floors.nil?
            unless floors.compact
              .select { |desc| desc.downcase == "floor" }.empty?
              return false
            end
          end
          windows = method_or_nil(adapter, :all_window_descriptions)
          unless windows.nil?
            unless windows.compact
              .select { |desc| desc.downcase == "window" }.empty?
              return false
            end
          end
          main_heating = method_or_nil(adapter, :all_main_heating_descriptions)
          unless main_heating.nil?
            unless main_heating.compact
              .select { |desc| desc.downcase == "main-heating" }.empty?
              return false
            end
          end
          main_heating_controls = method_or_nil(adapter, :all_main_heating_controls_descriptions)
          unless main_heating_controls.nil?
            unless main_heating_controls.compact
              .select { |desc| desc.downcase == "main-heating-controls" }.empty?
              return false
            end
          end
          true
        end,
      },
    ].freeze

    def validate(xml_adaptor)
      errors = RULES.reject { |rule| rule[:test].call(xml_adaptor) }

      errors.map { |error| { code: error[:name], title: error[:title] } }
    end
  end
end
