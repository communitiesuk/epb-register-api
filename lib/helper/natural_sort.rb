module Helper
  class NaturalSort
    def self.sort!(data)
      data.sort! do |a, b|
        a = a.to_hash
        b = b.to_hash

        address_a =
          [
            a[:address_line1],
            a[:address_line2],
            a[:address_line3],
            a[:address_line4],
            b[:postcode],
            a[:town],
          ]
            .reverse
            .compact
            .join(" ")
            .gsub(",", "")
            .gsub("  ", " ")
            .upcase
            .split(" ")

        address_b =
          [
            b[:address_line1],
            b[:address_line2],
            b[:address_line3],
            b[:address_line4],
            b[:postcode],
            b[:town],
          ]
            .reverse
            .compact
            .join(" ")
            .gsub(",", "")
            .gsub("  ", " ")
            .upcase
            .split(" ")

        res = 0

        address_a.each_with_index do |line, index|
          compare_to = address_b[index].nil? ? "" : address_b[index]
          if line.to_i != compare_to.to_i
            res = line.to_i < compare_to.to_i ? -1 : 1
            break
          elsif line != compare_to
            res = line <=> compare_to
          end
        end

        res
      end
    end
  end
end
