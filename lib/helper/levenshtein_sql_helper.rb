module Helper
  class LevenshteinSqlHelper
    STREET_PERMISSIVENESS = "0.35".freeze
    TOWN_PERMISSIVENESS = "0.3".freeze

    def self.levenshtein(property, bind, permissiveness = nil)
      levenshtein =
        "LEVENSHTEIN_LESS_EQUAL(LOWER(#{property}), LOWER(#{bind}), 5)"

      levenshtein << " < 5" if permissiveness

      levenshtein
    end
  end
end
