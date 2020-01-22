class AlterAssessorsMakeRegisteredBySmallint < ActiveRecord::Migration[6.0]
  def change
    change_column :assessors, :registered_by, :smallint
  end
end
