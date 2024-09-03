module UseCase
  class FetchAddressIdUpdateStats
    def initialize(gateway)
      @gateway = gateway
    end

    def execute(day_date)
      address_count = @gateway.fetch_updated_address_id_count(day_date)
      group_count = @gateway.fetch_updated_group_count(day_date)

      "The bulk linking rake has been run. On #{day_date.strftime('%v')} #{group_count} groups of addresses were linked, #{address_count} address ids were updated"
    end
  end
end
