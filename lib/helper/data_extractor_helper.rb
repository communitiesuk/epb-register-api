module Helper
  class DataExtractorHelper
    def fetch_data(raw_data, data_settings, kewy = "")
      data = {}

      traversed_settings = {}

      data_settings.each do |settings|
        key = settings["key"].to_sym
        path =
          if settings.key?("root")
            root = settings["root"].to_sym

            traversed_settings[root]["path"].map(&:to_sym)
          else
            []
          end

        path += settings["path"].map(&:to_sym)

        if path.include?(:"..")
          data[key] = kewy
        elsif raw_data.is_a?(Hash) && raw_data.key?(path[0])
          data[key] = raw_data.dig(*path)
        elsif settings.key?("default")
          data[key] = settings["default"]
        end

        if settings.key?("cast") && data[key]
          case settings["cast"]
          when "integer"
            data[key] = data[key].to_i
          when "snake_case"
            data[key] = data[key].underscore
          when "map"
            data[key] = settings["map"][data[key]]
          end
        end

        if settings.key?("extract")
          data[key] = [] unless data[key]

          if settings["extract"].any? { |item| item["path"].include?("..") }
            output_data = []
            data[key] =
              data[key].map do |inner_key, inner_data|
                inner_data = [inner_data] unless inner_data.is_a? Array

                inner_data.map do |inner_inner_data|
                  inner_inner_data =
                    fetch_data(
                      inner_inner_data,
                      settings["extract"],
                      inner_key.to_s,
                    )

                  next if inner_inner_data == {}

                  if settings.key?("required") && settings["required"]
                       .any? do |required_key|
                       !inner_inner_data[required_key.to_sym]
                     end
                    next
                  end

                  output_data.push(inner_inner_data)
                end
              end

            data[key] = output_data
          else
            data[key] = [data[key]] unless data[key].is_a? Array

            data[key] =
              data[key].map do |inner_data, _inner_key|
                fetch_data(inner_data, settings["extract"])
              end
          end
        end

        traversed_settings[key] = settings
      end

      data
    end
  end
end
