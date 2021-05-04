describe "Helper method address_base_filter" do
  {
    "C": true, # Commercial
    "CR01": true, # Bank
    "CC10": false, # Recycling site
    "CC11": false, # CCTV
    "CL09": false, # Beach hut
    "CR11": false, # ATM
    "CT01HT": false, # Heliport / helipad
    "CT02": false, # Bus shelter
    "CT03": false, # Car / coach parking sites
    "CT05": false, # Marina
    "CT06": false, # Mooring
    "CT07": false, # Railway asset
    "CT09": false, # Transport track / way
    "CT11": false, # Transport-related architecture
    "CT12": false, # Overnight lorry park
    "CT13": false, # Harbour / port / dock / dockyard
    "CU02": false, # Landfill
    "CU11": false, # Telephone box
    "CU12": false, # Dam
    "CZ02": false, # Information signage
    "CZ03": false, # Traffic information signage
    "L": false, # Land
    "LB99PI": true, # Pavilion / changing room
    "M": true, # Military
    "O": false, # Other
    "P": false, # Parent shell
    "R": true, # Residential
    "RD02": true, # Detached house
    "RC": false, # Car park space
    "RD07": false, # House boat
    "U": true, # Unclassified
    "Z": false, # Object of interest
    "ZM01OB": false, # Obelisk
    "ZM04": true, # Castle / historic ruin
    "ZS": true, # Stately home
    "ZV01": true, # Cellar
    "ZW99": true, # Place of worship
    "": true,
    "B": true,
  }.each do |class_code, is_accepted|

    context "when given an address class that starts with #{class_code}" do
      it is_accepted ? "it accepts it" : "it rejects it" do
        expect(Helper::AddressBaseFilter.filter_certifiable_addresses(class_code)).to be(is_accepted)
      end
    end
  end
end
