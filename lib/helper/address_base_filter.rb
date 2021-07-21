module Helper
  class AddressBaseFilter
    FILTERS = %i[filter_by_class filter_by_country].freeze

    def self.filter_certifiable_addresses(address_base_entry)
      FILTERS.all? { |filter| send filter, address_base_entry }
    end

    def self.filter_by_class(address_base_entry)
      class_code = address_base_entry[:CLASS]
      case class_code[0]
      when "C"
        # Commercial
        !class_code.start_with?(
          "CC10", # Recycling site
          "CC11", # CCTV
          "CL06QS", # Racquet sports facility (tennis court et al)
          "CL09", # Beach hut
          "CR11", # ATM
          "CT01HT", # Heliport / helipad
          "CT02", # Bus shelter
          "CT05", # Marina
          "CT06", # Mooring
          "CT07", # Railway asset
          "CT09", # Transport track / way
          "CT11", # Transport-related architecture
          "CT12", # Overnight lorry park
          "CT13", # Harbour / port / dock / dockyard
          "CU01", # Electricity Sub Station
          "CU02", # Landfill
          "CU11", # Telephone box
          "CU12", # Dam
          "CZ01", # Advertising hoarding
          "CZ02", # Information signage
          "CZ03", # Traffic information signage
        )
      when "L"
        # Land
        class_code.start_with?("LB99PI") # Pavilion / changing room
      when "M"
        # Military
        true
      when "O"
        # Other
        false
      when "P"
        class_code.start_with?("PP") # Property shell
      when "R"
        # Residential
        !class_code.start_with?(
          "RC", # Car park space
          "RD07", # House boat
          "RG02", # Garage/ lock-up
        )
      when "U"
        # Unclassified
        true
      when "Z"
        # Object of interest
        class_code.start_with?(
          "ZM04", # Castle / historic ruin
          "ZS", # Stately home
          "ZV01", # Cellar
          "ZW99", # Place of worship
        )
      else
        true
      end
    end

    def self.filter_by_country(address_base_entry)
      address_base_entry[:COUNTRY] != "S" # filter out Scottish addresses
    end
  end
end
