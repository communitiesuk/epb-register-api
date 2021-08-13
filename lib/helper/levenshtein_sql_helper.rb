module Helper
  class LevenshteinSqlHelper
    STREET_PERMISSIVENESS = "4".freeze
    TOWN_PERMISSIVENESS = "2".freeze

    def self.levenshtein(property, bind, permissiveness = nil)
      if permissiveness
        "LEVENSHTEIN_LESS_EQUAL(LOWER(#{property}), LOWER(#{bind}), #{
          permissiveness
        }) < #{permissiveness.to_i + 1}"
      else
        "LEVENSHTEIN(LOWER(#{property}), LOWER(#{bind}))"
      end
    end
  end
end
