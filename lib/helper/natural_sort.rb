module Helper
  class NaturalSort
    def self.sort!(data)
      data.sort! do |a, b|
        a = a.to_hash
        b = b.to_hash

        address_a =
          [
            a[:postcode],
            a[:town],
            a[:address_line4],
            a[:address_line3],
            a[:address_line2],
            a[:address_line1],
          ].map { |item| item.strip.upcase }

        address_b =
          [
            b[:postcode],
            b[:town],
            b[:address_line4],
            b[:address_line3],
            b[:address_line2],
            b[:address_line1],
          ].map { |item| item.strip.upcase }

        if compare_postcode(address_a, address_b) == 0
          check_address_line_for_number(address_a, address_b)
        else
          compare_postcode(address_a, address_b)
        end
      end
    end

    def self.compare_postcode(a, b)
      compare_to(a[0],b[0])
    end

    def self.check_address_line_for_number(a,b)
      address_lines_a = [a[2], a[3], a[4], a[5]]
      address_lines_b = [b[2], b[3], b[4], b[5]]

      property_a_number = 0
      property_a_letter = ""
      property_b_number = 0
      property_b_letter = ""

      address_lines_a.each do |line|
        if line.to_i != 0
          property_a_number = line.to_i
          if property_a_number.to_s != line.split(" ").first
            property_a_letter = line.split(" ").first[-1]
          end
        end
      end

      address_lines_b.each do |line|
        if line.to_i != 0
          property_b_number = line.to_i
          if property_b_number.to_s != line.split(" ").first
            property_b_letter = line.split(" ").first[-1]
          end
        end
      end

      compared = compare_to(property_a_number, property_b_number)
      compared == 0 ? compare_to(property_a_letter, property_b_letter) : compared
    end

    def self.compare_to(a,b)
      a <=> b
    end
  end
end
