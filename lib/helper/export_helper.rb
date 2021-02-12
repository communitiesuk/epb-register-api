module Helper
  class ExportHelper
    def self.to_csv(view_model_array)
      return "" if view_model_array.empty?

      csv_string =
        CSV.generate do |csv|
          csv << view_model_array.first.map { |key, _value| key.to_s.upcase }
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
  end
end
