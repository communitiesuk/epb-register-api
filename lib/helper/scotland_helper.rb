module Helper
  class ScotlandHelper
    SCOTTISH_SCHEMA = "scotland."
    PUBLIC_SCHEMA = "public."

    def self.select_schema(is_scottish)
      is_scottish ? SCOTTISH_SCHEMA : PUBLIC_SCHEMA
    end
  end
end
