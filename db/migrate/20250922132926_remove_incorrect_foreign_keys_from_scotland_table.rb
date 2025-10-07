class RemoveIncorrectForeignKeysFromScotlandTable < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key "scotland.assessments_xml", name: "fk_rails_e74bdd4563"
  end
end
