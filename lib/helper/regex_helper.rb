module Helper
  class RegexHelper
    ADDRESS_ID = '^RRN-(\d{4}-){4}\d{4}$|^UPRN-(\d{12})$'.freeze
    GREEN_DEAL_PLAN_ID = "^[a-zA-Z0-9]{12}$".freeze
    POSTCODE = "^[a-zA-Z0-9 ]{4,10}$".freeze
  end
end
