module Helper
  class ScotlandHelper
    SCOTTISH_SCHEMA = "scotland.".freeze
    PUBLIC_SCHEMA = "public.".freeze

    def self.select_schema(is_scottish)
      is_scottish ? SCOTTISH_SCHEMA : PUBLIC_SCHEMA
    end
  end
end
