module Domain
  class RecommendedImprovement
    attr_reader :sequence

    def initialize(sequence)
      @sequence = sequence
    end
  end
end
