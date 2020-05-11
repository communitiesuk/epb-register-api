module Helper
  class DataExtractorHelper
    def fetch_data(raw_data, data_settings)
      data = {}

      data_settings.each do |key, settings|
        path =
          if settings.key?(:root)
            root = settings[:root].to_sym

            data_settings[root][:path].map(&:to_sym)
          else
            []
          end

        path += settings[:path].map(&:to_sym)

        data[key] = raw_data.dig(*path)

        if settings.key?(:extract)
          unless data[key]
            data[key] = []
          end
          data[key] = [data[key]] unless data[key].is_a? Array
          data[key] = data[key].map do |inner_data|
            fetch_data(inner_data, settings[:extract])
          end
        end
      end

      data
    end
  end
end
