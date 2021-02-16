module Boundary
  class AwsMisconfigured < Boundary::TerminableError
    def initialize
      super(<<~MSG.strip)
        AWS is not configured correctly
        
        Please setup AWS CLI fully including a region
        https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html
      MSG
    end
  end
end
