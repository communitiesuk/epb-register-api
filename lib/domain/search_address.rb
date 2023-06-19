module Domain
  class SearchAddress
    def initialize(record)
      @assessment_id = record[:assessment_id]
      @address = record[:address]
    end

    def to_hash
      {
        assessment_id: @assessment_id,
        address: @address.slice(:address_line_1, :address_line_2, :address_line_3, :address_line_4).values.reject { |c| c.empty? }.join(" ").to_s.strip.downcase,
      }
    end
  end
end
