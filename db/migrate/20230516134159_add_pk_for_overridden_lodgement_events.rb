class AddPkForOverriddenLodgementEvents < ActiveRecord::Migration[7.0]
  def change
    # add pk for overridden_lodgement_events (arbitrary id)
    change_table :overridden_lodgement_events do |t|
      t.primary_key :id
    end
  end
end
