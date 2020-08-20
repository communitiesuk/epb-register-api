class AddAuthClientIdToAssessorsStatusEventsTable < ActiveRecord::Migration[6.0]
  def change
    add_column :assessors_status_events, :auth_client_id, :string
  end
end
