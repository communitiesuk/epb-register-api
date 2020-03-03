desc 'Import some random certificate data'

task :generate_certificate do
  ActiveRecord::Base.connection.execute('TRUNCATE TABLE domestic_energy_assessments RESTART IDENTITY')

  ActiveRecord::Base.logger = nil

  dwelling_type = ['end-terrace house', 'terrace house', 'flat', 'bungalow', 'mansion', 'castle']
  type_of_assessment = %w(RdSAP SAP)
  postcode = ['E2 0SZ', 'NW3 2UU', 'SW1A 2AA', 'SE1 1TE', 'SW1X 7XL', 'W1B 5BT', 'BH2 5BH', 'CF10 2EQ', 'TR19 7AA', 'M4 6WX' ]
  address_line1 = ['Flat 32', 'Milton Mews', 'Flat 22', 'First floor flat', '2D', 'Flat 99', '33 Caliban Tower', '1 Hamlet Building', '9 Peter Pan Building', '', '', '', '']
  address_line2 = ['7a Parkhill Road', 'Spooky Avenue', '9 Priti Patel Street', '11 Makup Street', '11 Mornington Crescent', 'Spooky Street', "Thomas Lane"]
  address_line3 = Array.new(20, '')
  address_line3.push('The Dormers')
  address_line4 = Array.new(100, '')
  address_line4.push('Westminster')
  town = ['Brighton', 'Bournemouth', 'London', 'Cardiff', 'Newcastle', 'Manchester', 'Bristol']

  200.times do |number|
    line_1 = address_line1.sample
    line_2 = address_line2.sample
    if line_1.empty?
      line_1 = line_2
      line_2 = ''
    end

    line_3 = address_line3.sample
    line_4 = address_line4.sample
    internal_postcode = postcode.sample
    date_of_assessment = '20' + rand(6..19).to_s.rjust(2, '0') + rand(1..12).to_s.rjust(2, '0') + rand(1..28).to_s.rjust(2, '0')
    date_registered = (Date.parse(date_of_assessment) + rand(1..5).day).strftime('%Y-%m-%d')
    date_of_expiry =  (Date.parse(date_of_assessment) + 10.year).strftime('%Y-%m-%d')
    internal_town = town.sample
    current_energy_efficiency_rating = rand(1..99)

    query =
      "INSERT INTO
        domestic_energy_assessments
          (
            assessment_id,
            date_of_assessment,
            date_registered,
            dwelling_type,
            type_of_assessment,
            total_floor_area,
            address_summary,
            current_energy_efficiency_rating,
            potential_energy_efficiency_rating,
            postcode,
            date_of_expiry,
            address_line1,
            address_line2,
            address_line3,
            address_line4,
            town
          )
        VALUES(
          '1234-5678-7890-8909-#{number.to_s.rjust(4, '0')}',
          '#{date_of_assessment}',
          '#{date_registered}',
          '#{dwelling_type.sample}',
          '#{type_of_assessment.sample}',
          '#{rand(20..200)}',
          '#{ActiveRecord::Base.sanitize_sql(line_1 + ', ' + line_2 + ', ' + internal_town + ', ' + internal_postcode)}',
          '#{current_energy_efficiency_rating}',
          '#{[current_energy_efficiency_rating + rand(1..20), 99].min}',
          '#{internal_postcode}',
          '#{date_of_expiry}',
          '#{ActiveRecord::Base.sanitize_sql(line_1)}',
          '#{ActiveRecord::Base.sanitize_sql(line_2)}',
          '#{line_3}',
          '#{line_4}',
          '#{internal_town}'
        )"

    ActiveRecord::Base.connection.execute(query)
  end
end
