module UseCase
  class FetchDomesticEpc
    class NotFoundException < Exception; end

    def initialize(domestic_epcs_gateway)
      @domestic_epcs_gateway = domestic_epcs_gateway
    end

    def execute(certificate_id)
      epc = @domestic_epcs_gateway.fetch(certificate_id)

      unless epc
        raise NotFoundException
      end

      epc
    end
  end
end
