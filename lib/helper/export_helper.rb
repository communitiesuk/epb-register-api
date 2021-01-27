module Helper
  class ExportHelper
    def self.to_csv(view_model_array)
      csv_string = CSV.generate do |csv|
        csv << view_model_array.first.map{|key, value| key.to_s.upcase}
        view_model_array.each do |model|
          csv << model.map { |key, value| value }
        end
      end
      csv_string =
        CSV.generate do |csv|
          csv << view_model_array.first.map { |key, _value| key.to_s.upcase }
          view_model_array.each do |model|
            csv << model.map { |_key, value| value }
          end
        end
      csv_string
    end
  end
end
