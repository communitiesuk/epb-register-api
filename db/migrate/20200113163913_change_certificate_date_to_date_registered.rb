class ChangeCertificateDateToDateRegistered < ActiveRecord::Migration[6.0]
  def self.up
    rename_column :domestic_epcs, :date_of_certificate, :date_registered
  end

  def self.down
    rename_column :domestic_epcs, :date_registered, :date_of_certificate
  end
end
