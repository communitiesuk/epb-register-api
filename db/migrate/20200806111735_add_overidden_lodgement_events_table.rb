class AddOveriddenLodgementEventsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :overidden_lodgement_events, { id: false } do |t|
      t.string :assessment_id
      t.jsonb :rule_triggers, default: []
      t.timestamps
    end
  end
end
