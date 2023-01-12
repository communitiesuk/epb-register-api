class SetStatementTimeout < ActiveRecord::Migration[7.0]
    def up
      database_name = connection.current_database
      execute "ALTER DATABASE #{database_name} SET statement_timeout='10min';"
    end

    def down
      database_name = connection.current_database
      execute "ALTER DATABASE #{database_name} SET statement_timeout=0;"
    end
end
