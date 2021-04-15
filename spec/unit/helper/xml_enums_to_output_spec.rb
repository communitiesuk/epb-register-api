shared_context "common" do
  before do
    @enum_built_form = {
      "1" => "Detached",
      "2" => "Semi-Detached",
      "3" => "End-Terrace",
      "4" => "Mid-Terrace",
      "5" => "Enclosed End-Terrace",
      "6" => "Enclosed Mid-Terrace",
      "NR" => "Not Recorded",
    }
    @enum_rdsap_main_fuel = {
      "0" =>
        "To be used only when there is no heating/hot-water system or data is from a community network",
      "1" =>
        "mains gas - this is for backwards compatibility only and should not be used",
      "2" =>
        "LPG - this is for backwards compatibility only and should not be used",
      "3" => "bottled LPG",
      "4" =>
        "oil - this is for backwards compatibility only and should not be used",
      "5" => "anthracite",
      "6" => "wood logs",
      "7" => "bulk wood pellets",
      "8" => "wood chips",
      "9" => "dual fuel - mineral + wood",
      "10" =>
        "electricity - this is for backwards compatibility only and should not be used",
      "11" =>
        "waste combustion - this is for backwards compatibility only and should not be used",
      "12" =>
        "biomass - this is for backwards compatibility only and should not be used",
      "13" =>
        "biogas - landfill - this is for backwards compatibility only and should not be used",
      "14" =>
        "house coal - this is for backwards compatibility only and should not be used",
      "15" => "smokeless coal",
      "16" => "wood pellets in bags for secondary heating",
      "17" => "LPG special condition",
      "18" => "B30K (not community)",
      "19" => "bioethanol",
      "20" => "mains gas (community)",
      "21" => "LPG (community)",
      "22" => "oil (community)",
      "23" => "B30D (community)",
      "24" => "coal (community)",
      "25" => "electricity (community)",
      "26" => "mains gas (not community)",
      "27" => "LPG (not community)",
      "28" => "oil (not community)",
      "29" => "electricity (not community)",
      "30" => "waste combustion (community)",
      "31" => "biomass (community)",
      "32" => "biogas (community)",
      "33" => "house coal (not community)",
      "34" => "biodiesel from any biomass source",
      "35" => "biodiesel from used cooking oil only",
      "36" => "biodiesel from vegetable oil only (not community)",
      "37" => "appliances able to use mineral oil or liquid biofuel",
      "51" => "biogas (not community)",
      "56" =>
        "heat from boilers that can use mineral oil or biodiesel (community)",
      "57" =>
        "heat from boilers using biodiesel from any biomass source (community)",
      "58" => "biodiesel from vegetable oil only (community)",
      "99" => "from heat network data (community)",
    }
    @enum_sap_main_fuel = {
      "1" => "Gas: mains gas",
      "2" => "Gas: bulk LPG",
      "3" => "Gas: bottled LPG",
      "4" => "Oil: heating oil",
      "7" => "Gas: biogas",
      "8" => "LNG",
      "9" => "LPG subject to Special Condition 18",
      "10" => "Solid fuel: dual fuel appliance (mineral and wood)",
      "11" => "Solid fuel: house coal",
      "12" => "Solid fuel: manufactured smokeless fuel",
      "15" => "Solid fuel: anthracite",
      "20" => "Solid fuel: wood logs",
      "21" => "Solid fuel: wood chips",
      "22" => "Solid fuel: wood pellets (in bags, for secondary heating)",
      "23" =>
        "Solid fuel: wood pellets (bulk supply in bags, for main heating)",
      "36" => "Electricity: electricity sold to grid",
      "37" => "Electricity: electricity displaced from grid",
      "39" => "Electricity: electricity, unspecified tariff",
      "41" => "Community heating schemes: heat from electric heat pump",
      "42" => "Community heating schemes: heat from boilers - waste combustion",
      "43" => "Community heating schemes: heat from boilers - biomass",
      "44" => "Community heating schemes: heat from boilers - biogas",
      "45" => "Community heating schemes: waste heat from power stations",
      "46" => "Community heating schemes: geothermal heat source",
      "48" => "Community heating schemes: heat from CHP",
      "49" => "Community heating schemes: electricity generated by CHP",
      "50" =>
        "Community heating schemes: electricity for pumping in distribution network",
      "51" => "Community heating schemes: heat from mains gas",
      "52" => "Community heating schemes: heat from LPG",
      "53" => "Community heating schemes: heat from oil",
      "54" => "Community heating schemes: heat from coal",
      "55" => "Community heating schemes: heat from B30D",
      "56" =>
        "Community heating schemes: heat from boilers that can use mineral oil or biodiesel",
      "57" =>
        "Community heating schemes: heat from boilers using biodiesel from any biomass source",
      "58" => "Community heating schemes: biodiesel from vegetable oil only",
      "72" => "biodiesel from used cooking oil only",
      "73" => "biodiesel from vegetable oil only",
      "74" => "appliances able to use mineral oil or liquid biofuel",
      "75" => "B30K",
      "76" => "bioethanol from any biomass source",
      "99" => "Community heating schemes: special fuel",
    }
  end
end

describe Helper::XmlEnumsToOutput do
  let(:helper) { described_class }
  include_context("common")

  context "when a Built-Form XML value is passed to the BUILT_FORM enum" do
    context "and the XML does not have the specified node" do
      it "returns nil for Open Data Communities" do
        response = helper.xml_value_to_string(nil)
        expect(response).to be_nil
      end
    end

    context "when the XML does have the specified node" do
      it "returns the string when you pass as the argument" do
        @enum_built_form.each do |key, value|
          response = helper.xml_value_to_string(key)
          expect(response).to eq(value)
        end
      end
    end

    context "when the XML contains any other value outside of the enum" do
      it "returns nil for Open Data Communities" do
        response = helper.xml_value_to_string({ "hello": 20 })
        expect(response).to be_nil
      end

      it "returns nil for Open Data Communities" do
        response = helper.xml_value_to_string("Any other value")
        expect(response).to be_nil
      end
    end
  end

  context "when an EnergyEfficiencySummaryCode type XML value is passed to the RATINGS enum" do
    context "and the XML has a value contained in the enum" do
      it "returns the correct string value for Open Data Communities" do
        expect(Helper::XmlEnumsToOutput.energy_rating_string("2")).to eq("Poor")
        expect(Helper::XmlEnumsToOutput.energy_rating_string("0")).to eq("N/A")
        expect(Helper::XmlEnumsToOutput.energy_rating_string("4")).to eq("Good")
      end
    end

    context "and the XML has a value outside of the enum" do
      it "returns nil if the wrong type or key out of range is passed" do
        expect(Helper::XmlEnumsToOutput.energy_rating_string("A")).to be_nil
        expect(Helper::XmlEnumsToOutput.energy_rating_string("10")).to be_nil
        expect(Helper::XmlEnumsToOutput.energy_rating_string([0, 0])).to be_nil
      end
    end
  end

  context "when the Energy-Tariff XML value is passed to the ENERGY_TARIFF enum" do
    it "finds the value in the enum and returns the correct string value" do
      expect(Helper::XmlEnumsToOutput.energy_tariff("1", 2)).to eq("dual")
      expect(Helper::XmlEnumsToOutput.energy_tariff("1", 3)).to eq(
        "standard tariff",
      )
      expect(Helper::XmlEnumsToOutput.energy_tariff("ND", 3)).to eq(
        "not applicable",
      )
    end
    it "does not find the value in the enum and returns the same value" do
      expect(Helper::XmlEnumsToOutput.energy_tariff("test")).to eq("test")
    end
  end

  context "when the Main-Fuel-Type XML value is passed to the RDSAP_MAIN_FUEL enum" do
    it "does not find a value in the enum and returns nil" do
      expect(Helper::XmlEnumsToOutput.main_fuel_rdsap(nil)).to be_nil
      expect(Helper::XmlEnumsToOutput.main_fuel_rdsap("hello")).to be_nil
    end
    it "returns nil if the value is not the correct type" do
      expect(Helper::XmlEnumsToOutput.main_fuel_rdsap({ "hello": 1 })).to be_nil
      expect(Helper::XmlEnumsToOutput.main_fuel_rdsap(1)).to be_nil
    end

    it "and the value is in the lookup it return the expected string" do
      @enum_rdsap_main_fuel.each do |key, value|
        response = helper.main_fuel_rdsap(key)
        expect(response).to eq(value)
      end
    end
  end

  context "when the Main-Fuel-Type XML value is passed to the SAP_MAIN_FUEL enum" do
    it "does not find a value in the enum and returns nil" do
      expect(Helper::XmlEnumsToOutput.main_fuel_sap(nil)).to be_nil
      expect(
        Helper::XmlEnumsToOutput.main_fuel_sap("any other value"),
      ).to be_nil
    end
    it "returns nil if the value is not the correct type" do
      expect(Helper::XmlEnumsToOutput.main_fuel_sap({ "hello": 1 })).to be_nil
      expect(Helper::XmlEnumsToOutput.main_fuel_sap(1)).to be_nil
    end
    it "and the value is in the lookup it return the expected string" do
      @enum_sap_main_fuel.each do |key, value|
        response = helper.main_fuel_sap(key)
        expect(response).to eq(value)
      end
    end
  end

  context "when the Glazing-Type XML value is passed to to the RdSAP glazed_type enum" do
    it "does not find a value in the enum and returns nil" do
      expect(Helper::XmlEnumsToOutput.glazed_type_rdsap(nil)).to be_nil
      expect(
        Helper::XmlEnumsToOutput.glazed_type_rdsap("Any other value"),
      ).to be_nil
    end
    it "and the value is in the lookup, it returns the expected string" do
      expect(Helper::XmlEnumsToOutput.glazed_type_rdsap("1")).to eq(
        "double glazing installed before 2002",
      )
      expect(Helper::XmlEnumsToOutput.glazed_type_rdsap("3")).to eq(
        "double glazing, unknown install date",
      )
      expect(Helper::XmlEnumsToOutput.glazed_type_rdsap("5")).to eq(
        "single glazing",
      )
    end
    it "returns nil if the value is not the correct type" do
      expect(
        Helper::XmlEnumsToOutput.glazed_type_rdsap({ "hash": "3" }),
      ).to be_nil
      expect(Helper::XmlEnumsToOutput.glazed_type_rdsap(3)).to be_nil
    end
  end

  context "when the Glazing-Area XML value is passed to to the RdSAP glazed_area enum" do
    it "does not find a value in the enum and returns nil" do
      expect(Helper::XmlEnumsToOutput.glazed_area_rdsap(nil)).to be_nil
      expect(
        Helper::XmlEnumsToOutput.glazed_area_rdsap("Any other value"),
      ).to be_nil
    end
    it "and the value is in the lookup, it returns the expected string" do
      expect(Helper::XmlEnumsToOutput.glazed_area_rdsap("1")).to eq("Normal")
      expect(Helper::XmlEnumsToOutput.glazed_area_rdsap("3")).to eq(
        "Less Than Typical",
      )
      expect(Helper::XmlEnumsToOutput.glazed_area_rdsap("5")).to eq(
        "Much Less Than Typical",
      )
      expect(Helper::XmlEnumsToOutput.glazed_area_rdsap("ND")).to eq(
        "Not Defined",
      )
    end
  end

  context "when the Tenure XML value is passed to the tenure enum" do
    it "and the value is in the lookup, it returns the expected string" do
      expect(Helper::XmlEnumsToOutput.tenure("1")).to eq("Owner-occupied")
      expect(Helper::XmlEnumsToOutput.tenure("ND")).to eq(
        "Not defined - use in the case of a new dwelling for which the intended tenure in not known. It is not to be used for an existing dwelling",
      )
    end
    it "returns the xml value if the entered value is not in the lookup" do
      expect(Helper::XmlEnumsToOutput.tenure("Hello, this is a value")).to eq(
        "Hello, this is a value",
      )
      expect(Helper::XmlEnumsToOutput.tenure(nil)).to be_nil
      expect(Helper::XmlEnumsToOutput.tenure(%w[1 2 3])).to eq(%w[1 2 3])
    end
  end

  context "when the Transaction-Type xml value is passed to the transaction type enum" do
    it "and the value is in the lookup, it returns the expected string" do
      expect(Helper::XmlEnumsToOutput.transaction_type("1")).to eq(
        "marketed sale",
      )
      expect(Helper::XmlEnumsToOutput.transaction_type("3", "3")).to eq(
        "rental (social) - this is for backwards compatibility only and should not be used",
      )
      expect(Helper::XmlEnumsToOutput.transaction_type("12", "3")).to eq(
        "Stock condition survey",
      )
      expect(Helper::XmlEnumsToOutput.transaction_type("12")).to eq(
        "RHI application",
      )
      expect(Helper::XmlEnumsToOutput.transaction_type("13", "3")).to eq("13")
    end
  end

  context "when the Construction-Age-Band xml value is passed to the construction age band enum" do
    it "and the value is in the lookup, it returns the expected string" do
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "A",
          "RdSAP-Schema-20.0.0",
        ),
      ).to eq("England and Wales: before 1900")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "B",
          "RdSAP-Schema-18.0",
        ),
      ).to eq("England and Wales: 1900-1929")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "C",
          "RdSAP-Schema-17.1",
        ),
      ).to eq("England and Wales: 1930-1949")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "K",
          "SAP-Schema-18.0.0",
        ),
      ).to eq("England and Wales: 2007-2011")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "K",
          "SAP-Schema-16.3",
        ),
      ).to eq("England and Wales: 2007 onwards")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "K",
          "SAP-Schema-12.0",
          2,
        ),
      ).to eq("Post-2006")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "K",
          "SAP-Schema-12.0",
          3,
        ),
      ).to eq("England and Wales: 2007 onwards")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "K",
          "SAP-Schema-10.2",
        ),
      ).to eq("England and Wales: 2007-2011")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "K",
          "RdSAP-Schema-20.0.0",
        ),
      ).to eq("England and Wales: 2007-2011")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "NR",
          "SAP-Schema-16.1",
          2,
        ),
      ).to eq("Not recorded")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "L",
          "SAP-Schema-18.0.0",
        ),
      ).to eq("England and Wales: 2012 onwards")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "0",
          "SAP-Schema-16.3",
          2,
        ),
      ).to eq("Not applicable")
    end

    it "returns the xml value if the entered value is not in the lookup" do
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "NR",
          "SAP-Schema-16.0",
          2,
        ),
      ).to eq("NR")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "NR",
          "SAP-Schema-16.3",
          3,
        ),
      ).to eq("NR")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "L",
          "SAP-Schema-16.3",
        ),
      ).to eq("L")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "0",
          "SAP-Schema-17.0",
        ),
      ).to eq("0")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "0",
          "SAP-Schema-16.3",
          3,
        ),
      ).to eq("0")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "0",
          "SAP-Schema-10.2",
        ),
      ).to eq("0")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          nil,
          "SAP-Schema-18.0.0",
        ),
      ).to be_nil
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "Any other content",
          "RdSAP-Schema-20.0.0",
        ),
      ).to eq("Any other content")
      expect(
        Helper::XmlEnumsToOutput.construction_age_band_lookup(
          "",
          "RdSAP-Schema-20.0.0",
        ),
      ).to be_nil
    end
  end

  context "when the Property-Type xml value is passed to the transaction type enum" do
    it "and the value is in the lookup, it returns the expected string" do
      expect(Helper::XmlEnumsToOutput.property_type("0")).to eq("House")
      expect(Helper::XmlEnumsToOutput.property_type("4")).to eq("Park home")
    end
  end

  context "when the Heat-Loss-Corridor xml value is passed to the transaction type enum" do
    it "does not find a value in the enum and returns nil" do
      expect(Helper::XmlEnumsToOutput.heat_loss_corridor(nil)).to be_nil
      expect(
        Helper::XmlEnumsToOutput.heat_loss_corridor("Any other value"),
      ).to eq("Any other value")
    end
    it "and the value is in the lookup, it returns the expected string" do
      expect(Helper::XmlEnumsToOutput.heat_loss_corridor("0")).to eq(
        "no corridor",
      )
      expect(Helper::XmlEnumsToOutput.heat_loss_corridor("2")).to eq(
        "unheated corridor",
      )
    end
  end

  context "when the Mechanical-Ventilation xml value is passed to the transaction type enum" do
    it "does not find a value in the enum and returns nil" do
      expect(
        Helper::XmlEnumsToOutput.mechanical_ventilation(
          nil,
          "RdSAP-Schema-20.0.0",
        ),
      ).to be_nil
      expect(
        Helper::XmlEnumsToOutput.mechanical_ventilation(
          "Any other value",
          "RdSAP-Schema-20.0.0",
        ),
      ).to eq("Any other value")
    end
    it "and the value is in the lookup, it returns the expected string" do
      expect(
        Helper::XmlEnumsToOutput.mechanical_ventilation(
          "0",
          "RdSAP-Schema-20.0.0",
        ),
      ).to eq("natural")
      expect(
        Helper::XmlEnumsToOutput.mechanical_ventilation(
          "2",
          "RdSAP-Schema-20.0.0",
        ),
      ).to eq("mechanical, extract only")
      expect(
        Helper::XmlEnumsToOutput.mechanical_ventilation(
          "0",
          "SAP-Schema-11.2",
          2,
        ),
      ).to eq("none")
      expect(
        Helper::XmlEnumsToOutput.mechanical_ventilation(
          "2",
          "SAP-Schema-11.2",
          2,
        ),
      ).to eq("mechanical - non recovering")
    end
  end

  context "when the CECP Transaction-Type xml value is passed to the transaction type enum" do
    it "and the value is in the lookup, it returns the expected string" do
      expect(Helper::XmlEnumsToOutput.cepc_transaction_type("1")).to eq(
        "Mandatory issue (Marketed sale)",
      )
      expect(Helper::XmlEnumsToOutput.cepc_transaction_type("3")).to eq(
        "Mandatory issue (Property on construction).",
      )
      expect(Helper::XmlEnumsToOutput.cepc_transaction_type("12")).to eq("12")
    end
  end
end
