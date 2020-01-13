module UseCase
  class FetchDomesticEpc
    class NotFoundException < Exception; end

    def initialize(domestic_epcs_gateway)
      @domestic_epcs_gateway = domestic_epcs_gateway
    end

    def execute(certificate_id)
      epc = @domestic_epcs_gateway.fetch(certificate_id)

      raise NotFoundException unless epc

      epc
    end
  end
end
