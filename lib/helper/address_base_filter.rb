module Helper
  class AddressBaseFilter
    def self.filter_certifiable_addresses(class_code)

      case class_code[0]
      when "C" # Commercial
        !class_code.starts_with?("CC10", # Recycling site
                                 "CC11", # CCTV
                                 "CL09", # Beach hut
                                 "CR11", # ATM
                                 "CT01HT", # Heliport / helipad
                                 "CT02", # Bus shelter
                                 "CT03", # Car / coach parking sites
                                 "CT05", # Marina
                                 "CT06", # Mooring
                                 "CT07", # Railway asset
                                 "CT09", # Transport track / way
                                 "CT11", # Transport-related architecture
                                 "CT12", # Overnight lorry park
                                 "CT13", # Harbour / port / dock / dockyard
                                 "CU02", # Landfill
                                 "CU11", # Telephone box
                                 "CU12", # Dam
                                 "CZ02", # Information signage
                                 "CZ03", # Traffic information signage
        )
      when "L" # Land
        class_code.starts_with?("LB99PI") # Pavilion / changing room
      when "M" # Military
        true
      when "O" # Other
        false
      when "P" # Parent shell
        false
      when "R" # Residential
        !class_code.starts_with?("RC", # Car park space
                                 "RD07", # House boat
        )
      when "U" # Unclassified
        true
      when "Z" # Object of interest
        class_code.starts_with?("ZM04", # Castle / historic ruin
                                "ZS", # Stately home
                                "ZV01", # Cellar
                                "ZW99", # Place of worship
        )
      else
        true
      end
    end
  end
end
