module Helper
  class EnergyBandCalculator
    def self.domestic(number)
      case number
      when proc { |n| n <= 20 }
        "g"
      when 21..38
        "f"
      when 39..54
        "e"
      when 55..68
        "d"
      when 69..80
        "c"
      when 81..91
        "b"
      else
        "a"
      end
    end

    def self.commercial(number)
      case number
      when proc { |n| n <= -1 }
        "a+"
      when 0..25
        "a"
      when 26..50
        "b"
      when 51..75
        "c"
      when 76..100
        "d"
      when 101..125
        "e"
      when 126..150
        "f"
      else
        "g"
      end
    end
  end
end
