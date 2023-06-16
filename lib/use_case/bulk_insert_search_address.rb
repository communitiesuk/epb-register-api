module UseCase
  class BulkInsertSearchAddress
    def initialize(search_address_gateway)
      @search_address_gateway = search_address_gateway
    end

    def execute
      @search_address_gateway.bulk_insert
    end
  end
end
