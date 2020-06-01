class AddFuzzyStringMatchingExtension < ActiveRecord::Migration[6.0]
  def change
    enable_extension "fuzzystrmatch"
  end
end
