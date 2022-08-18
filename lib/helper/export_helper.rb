module Helper
  class ExportHelper
    SAP_HEADERS = {
      improvement_summary: "IMPROVEMENT_SUMMARY_TEXT",
      improvement_description: "IMPROVEMENT_DESCR_TEXT",
      improvement_item: "IMPROVEMENT_SUMMARY",
      sequence: "IMPROVEMENT_ITEM",
      improvement_code: "IMPROVEMENT_ID",
    }.freeze

    def self.to_csv(view_model_array)
      return "" if view_model_array.empty?

      columns = view_model_array.first.keys.clone
      headers = columns.map { |item| item.to_s.upcase.strip }.clone

      CSV.generate do |csv|
        csv << headers
        view_model_array.each do |hash|
          csv << columns.map do |key, _value|
            if hash[key.to_sym].is_a?(String)
              (hash[key.to_sym]).to_s
            else
              hash[key.to_sym]
            end
          end
        end
      end
    end

    def self.report_type_to_s(type_of_assessment)
      if type_of_assessment.is_a?(Array)
        type_of_assessment.join(",")
      else
        type_of_assessment
      end
    end

    def self.remove_line_breaks(data)
      data.each do |assessment|
        assessment.each do |key, value|
          if !value.is_a?(String)
            break
          elsif !value.frozen?
            remove_line_break_and_extra_spaces(value)
          elsif value.frozen?
            assessment[key] = remove_line_break_and_extra_spaces(value.dup)
          end
        end
      end
    end

    def self.remove_line_break_and_extra_spaces(value)
      value.delete!("\n")
      value.delete!("\r")
      value.squeeze!(" ")
      value
    end
  end
end
