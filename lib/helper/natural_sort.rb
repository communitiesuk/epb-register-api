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
          ].map { |item| item.strip.upcase }

        address_b =
          [
            b[:postcode],
            b[:address_line4],
            b[:address_line3],
            b[:address_line2],
            b[:address_line1],
          ].map { |item| item.strip.upcase }

        postcode_comparison = compare_postcode(address_a, address_b)
        if postcode_comparison == 0
          address_line_comparison = compare_address_line_for_number(address_a, address_b)
          address_line_comparison == 0 ? compare_flat_numbers(address_a,address_b) : address_line_comparison

          if address_line_comparison == 0
            flat_number_comparison = compare_flat_numbers(address_a,address_b)
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
      compare_to(a[0],b[0])
    end

    def self.compare_address_line_for_number(a,b)
      address_lines_a = [a[1], a[2], a[3], a[4]]
      address_lines_b = [b[1], b[2], b[3], b[4]]

      property_a_number, property_a_letter = get_property_number_and_letter(address_lines_a)
      property_b_number, property_b_letter = get_property_number_and_letter(address_lines_b)

      compared = compare_to(property_a_number, property_b_number)
      compared == 0 ? compare_to(property_a_letter, property_b_letter) : compared
    end

    def self.get_property_number_and_letter(address_block)
      property_number = 0
      property_letter = ""
      address_block.each do |line|
        if line.to_i != 0
          property_number = line.to_i
          line_split = line.split(" ")
          remove_punctuation = line_split.first.sub(",","").sub("-"," ")

          if property_number.to_s != line_split.first
            if remove_punctuation.split(" ")[1]&.scan(/\d+/) != []
              property_letter = remove_punctuation.split(" ")[1].to_s
            else
            property_letter = line_split.first[-1]
           end
          end
        end
      end
      return property_number, property_letter
    end

    def self.compare_flat_numbers(a,b)
      flat_number_a = get_flat_number(a)
      flat_number_b = get_flat_number(b)

      compare_to(flat_number_a,flat_number_b)
    end

    def self.get_flat_number(a)
      numbers_in_address = a[1..4].reverse.join(" ").scan(/\d+/)
      if numbers_in_address != [] && numbers_in_address.count > 1
        numbers_in_address.first.to_i
      else
        0
      end
    end

    def self.compare_addresses_alphabetically(a, b)
      address_a = a[1..4].reverse.join(" ")
      address_b = b[1..4].reverse.join(" ")

      numbers_in_address_a = address_a.scan(/\d+/)
      numbers_in_address_b = address_b.scan(/\d+/)

      if numbers_in_address_a.count < 2 && numbers_in_address_b.count < 2
        comparison_result = 0
        address_a.split("").each_with_index do |char, index|
          if char == address_b[index]
            next
          else
            comparison_result = compare_to(char, address_b[index])
            break
          end
        end
        comparison_result
      else
        0
      end
    end

    def self.compare_to(a,b)
      a <=> b
    end
  end
end
