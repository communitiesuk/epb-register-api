# frozen_string_literal: true

module Helper
  module RdsapValidator
    class SuggestedImprovementSequence
      attr_reader :description

      def initialize
        @description = 'Sequences must contain 0 and be continuous'
      end

      def validates?(domestic_energy_assessment)
        improvements = domestic_energy_assessment.recommended_improvements

        return true if improvements == []

        sequences = improvements.map(&:sequence)

        sequences.include?(0) &&
          sequences.sort.each_cons(2).all? { |x, y| y == x + 1 }
      end
    end
  end
end
