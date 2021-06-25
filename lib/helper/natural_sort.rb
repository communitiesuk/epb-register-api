module Helper
  class NaturalSort
    def self.sort!(data)
      data.sort! do |a, b|
        a = a.to_hash
        b = b.to_hash

        address_a =
          [
            a[:postcode],
            a[:address_line4],
            a[:address_line3],
            a[:address_line2],
            a[:address_line1],
          ].map { |item| item.to_s.strip.upcase.tr(",", "") }

        address_b =
          [
            b[:postcode],
            b[:address_line4],
            b[:address_line3],
            b[:address_line2],
            b[:address_line1],
          ].map { |item| item.to_s.strip.upcase.tr(",", "") }

        postcode_comparison = compare_postcode(address_a, address_b)
        if postcode_comparison == 0
          address_line_comparison =
            compare_address_line_for_number(address_a, address_b)

          if address_line_comparison == 0
            flat_number_comparison = compare_flat_numbers(address_a, address_b)
            flat_number_comparison == 0 ? compare_addresses_alphabetically(address_a, address_b) : flat_number_comparison
          else
            address_line_comparison
          end
        else
          postcode_comparison
        end
      end
    end

    def self.compare_postcode(a, b)
      compare_to(a[0], b[0])
    end

    def self.compare_address_line_for_number(a, b)
      address_lines_a = [a[1], a[2], a[3], a[4]]
      address_lines_b = [b[1], b[2], b[3], b[4]]

      property_a_number, property_a_letter =
        get_property_number_and_letter(address_lines_a)
      property_b_number, property_b_letter =
        get_property_number_and_letter(address_lines_b)

      compared = compare_to(property_a_number, property_b_number)
      if compared == 0
        compare_to(property_a_letter, property_b_letter)
      else
        compared
      end
    end

    def self.get_property_number_and_letter(address_block)
      property_number = 0
      property_letter = ""
      address_block.each do |line|
        next unless line.to_i != 0

        property_number = line.to_i
        line_split = line.split(" ")

        next unless property_number.to_s != line_split.first

        remove_hyphen = line_split.first.tr("-", " ")
        address_line_digits = remove_hyphen.split(" ")[1]&.scan(/\d+/)

        property_letter =
          if address_line_digits != [] && !address_line_digits.nil?
            remove_hyphen.split(" ")[1].to_s
          else
            line_split.first[-1]
          end
      end
      [property_number, property_letter]
    end

    def self.compare_flat_numbers(a, b)
      flat_number_a = get_flat_number(a)
      flat_number_b = get_flat_number(b)

      compare_to(flat_number_a, flat_number_b)
    end

    def self.get_flat_number(a)
      numbers_in_address = a[1..4].reverse.join(" ").scan(/\d+/)
      if !numbers_in_address.empty? && numbers_in_address.count > 1
        numbers_in_address.first.to_i
      else
        # No numbers or only single number present (can't assume flat number)
        0
      end
    end

    def self.compare_addresses_alphabetically(a, b)
      address_a = a[1..4].reverse.join(" ")
      address_b = b[1..4].reverse.join(" ")

      compare_to(address_a, address_b)
    end

    def self.compare_to(a, b)
      a <=> b
    end
  end
end
