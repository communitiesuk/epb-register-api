module Domain
  class SearchAddress
    def initialize(record)
      @assessment_id = record[:assessment_id]
      @address = record[:address]
    end

    def to_hash
      {
        assessment_id: @assessment_id,
        address: @address.slice(:address_line1, :address_line2, :address_line3, :address_line4).values.reject(&:blank?).join(" ").to_s.strip.downcase,
      }
    end
  end
end
