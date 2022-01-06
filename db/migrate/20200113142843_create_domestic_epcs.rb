class CreateDomesticEpcs < ActiveRecord::Migration[6.0]
  def change
    create_table :domestic_epcs, id: false do |t|
      t.string :certificate_id
      t.datetime :date_of_assessment
      t.datetime :date_of_certificate
      t.string :dwelling_type
      t.string :type_of_assessment
      t.bigint :total_floor_area
      t.string :address_summary
    end

    execute("ALTER TABLE domestic_epcs ADD PRIMARY KEY (certificate_id)")
  end
end
