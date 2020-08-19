class AssessorsStatusUpdates < ActiveRecord::Migration[6.0]
  def change
    create_table :assessors_status_events do |t|
      t.jsonb :assessor, default: {}
      t.string :scheme_assessor_id
      t.string :qualification_type
      t.string :previous_status
      t.string :new_status
      t.timestamp :recorded_at
    end
  end
end
