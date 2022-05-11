module Domain
  class AssessmentReferenceList
    include Enumerable

    def initialize(*rrns)
      @rrns = rrns.sort
    end

    def each(&block)
      if block_given?
        @rrns.each(&block)
      else
        @rrns.each
      end
    end

    def references
      @rrns
    end
  end
end
