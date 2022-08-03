class RenameOverriddenLodgementEventTableForSpelling < ActiveRecord::Migration[7.0]
  def change
    rename_table :overidden_lodgement_events, :overridden_lodgement_events
  end
end
