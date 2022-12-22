class RemoveChannelIslandsAndIomFromAddressBase < ActiveRecord::Migration[7.0]
  def up
    # remove address base entries with postcodes from Isle of Man (IM) or the Channel Islands (JE, GY)
    execute "DELETE FROM address_base WHERE postcode LIKE 'IM%' OR postcode LIKE 'JE%' OR postcode LIKE 'GY%'"
  end

  def down
    # we can just do nothing as replenishing the address base data is out of scope of migrations
  end
end
