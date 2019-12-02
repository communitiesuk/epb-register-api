module Helper

  class Json
    def convert_to_ruby_hash(json)
      JSON.parse(json, symbolize_names: true)
    end
  end
end