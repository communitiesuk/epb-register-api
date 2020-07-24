module Helper
  class LevenshteinSqlHelper
    STREET_PERMISSIVENESS = "0.35".freeze
    TOWN_PERMISSIVENESS = "0.3".freeze

    def self.levenshtein(property, bind, permissiveness = nil)
      levenshtein =
        "LEVENSHTEIN(LOWER(#{property}), LOWER(#{
          bind
        }))::decimal / GREATEST(length(#{property}), length(#{bind}))"

      levenshtein << " < #{permissiveness}" if permissiveness

      levenshtein
    end
  end
end
