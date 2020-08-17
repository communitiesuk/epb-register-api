module Helper
  class RegexHelper
    ADDRESS_ID = '^RRN-(\d{4}-){4}\d{4}$|^UPRN-(\d{12})$'.freeze
    GREEN_DEAL_PLAN_ID = "^[a-zA-Z0-9]{12}$".freeze

    POSTCODE =
      "^((([A-Za-z][0-9]{1,2})|(([A-Za-z][A-Ha-hJ-Yj-y][0-9]{1,2})|(([AZa-z][0-9][A-Za-z])|([A-Za-z][A-Ha-hJ-Yj-y][0-9]?[A-Za-z]))))\\s?[0-9][A-Za-z]{2})$"
        .freeze
  end
end
