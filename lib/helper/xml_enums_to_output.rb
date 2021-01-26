module Helper
  class XmlEnumsToOutput

    RATINGS = ["N/A", "Very Good", "Good", "Average", "Poor", "Very Poor"].freeze
    BUILT_FORM = {
      "1" => "Detached",
      "2" => "Semi-Detached",
      "3" => "End-Terrace",
      "4" => "Mid-Terrace",
      "5" => "Enclosed End-Terrace",
      "6" => "Enclosed Mid-Terrace",
      "NR" => "Not Recorded",
    }.freeze


    def self.xml_value_to_string(number)
      BUILT_FORM[number]
    end

    def self.energy_rating_string(input)
      number = input.to_i
      number > RATINGS.length ? "N/A" : RATINGS[number]
    end

  end





end
