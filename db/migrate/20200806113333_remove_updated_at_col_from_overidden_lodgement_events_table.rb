class RemoveUpdatedAtColFromOveriddenLodgementEventsTable < ActiveRecord::Migration[6.0]
  def change
    remove_column :overidden_lodgement_events, :updated_at
  end
end
