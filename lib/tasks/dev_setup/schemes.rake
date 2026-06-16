namespace :dev_data do
  desc "Insert schemes data"
  task :generate_schemes do
    Tasks::TaskHelpers.quit_if_production
    ActiveRecord::Base.connection.exec_query("TRUNCATE TABLE schemes RESTART IDENTITY CASCADE")

    ActiveRecord::Base.logger = nil

    # names = ["CIBSE Certification Limited",
    #          "ECMK",
    #          "Elmhurst Energy Systems Ltd",
    #          "Sterling Accreditation Ltd",
    #          "Stroma Certification Ltd",
    #          "Quidos Limited",
    #          "Kaizen Certification Ltd",
    #          "Bacra EPC Scheme",
    #          "ABE",
    #          "CIH",
    #          "RIAS",
    #          "Unknown Assessors"]
    #
    # names.each do |name|
    #   active_scotland = name == "Kaizen Certification Ltd" ? false : true
    #   active_eng_wls_nir = name == "Bacra EPC Scheme" ? false : true
    #   query = "INSERT INTO schemes (name, active, active_scotland, active_eng_wls_nir) VALUES('#{name}', 'true', '#{active_scotland}', '#{active_eng_wls_nir}')"
    #
    #   ActiveRecord::Base.connection.exec_query(query)
    # end

    names = [
      "CIBSE Certification Limited",
      "ECMK",
      "Elmhurst Energy Systems Ltd",
      "Sterling Accreditation Ltd",
      "Stroma Certification Ltd",
      "Quidos Limited",
      "Kaizen Certification Ltd",
      "Bacra EPC Scheme",
      "ABE",
      "CIH",
      "RIAS",
      "Unknown Assessors",
    ]

    overrides = {
      "Kaizen Certification Ltd" => { active_scotland: false },
      "Bacra EPC Scheme" => { active_eng_wls_nir: false },
    }

    names.each do |name|
      attrs = {
        name: name,
        active: true,
        active_scotland: true,
        active_eng_wls_nir: true,
      }.merge(overrides.fetch(name, {}))

      Scheme.create!(attrs)
    end
  end
end
