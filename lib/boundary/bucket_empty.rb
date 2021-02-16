module Boundary
  class BucketEmpty < Boundary::TerminableError
    def initialize(details)
      bucket, prefix = details

      super(<<~MSG.strip)
        The bucket "#{bucket}" has no files at the prefix "#{prefix}"
      MSG
    end
  end
end
