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

      csv_string =
        CSV.generate do |csv|
          csv << view_model_array.first.map do |key, _value|
            key.to_s.upcase.strip
          end
          view_model_array.each do |model|
            csv << model.map { |_key, value| value }
          end
        end
      csv_string
    end

    def self.report_type_to_s(type_of_assessment)
      if type_of_assessment.is_a?(Array)
        type_of_assessment.join(",")
      else
        type_of_assessment
      end
    end

    def self.flatten_domestic_rr_response(response)
      flattened_array = []
      response.each { |hash| flattened_array << hash[:recommendations] }
      flattened_array.flatten
    end

    def self.convert_header_values(report_values)
      return_array = []
      report_values.each do |item|
        value = SAP_HEADERS[item.downcase.to_sym]
        return_array << (value.nil? ? item.upcase : value.upcase)
      end

      return_array
    end
  end
end
