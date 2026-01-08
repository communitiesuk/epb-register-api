class AddBtreeGinExtension < ActiveRecord::Migration[8.1]
  def change
    enable_extension "btree_gin"
  end
end
