module Helper
  class XmlEnumsToOutput

    @enum_built_form = {
      "1" => "Detached",
      "2" => "Semi-Detached",
      "3" => "End-Terrace",
      "4" => "Mid-Terrace",
      "5" => "Enclosed End-Terrace",
      "6" => "Enclosed Mid-Terrace",
      "NR" => "Not Recorded",
    }
    def self.xml_value_to_string(number)
      @enum_built_form[number]
    end
  end
end
