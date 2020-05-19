class CreateLodgementAttemptsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :lodgement_attempts do |t|
      t.string :url
      t.text :request_header
      t.text :request_body
      t.integer :scheme_id
      t.datetime :submitted_at
      t.string :failure_reason
      t.integer :status, default: 0
    end
  end
end
