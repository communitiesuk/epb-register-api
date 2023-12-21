module OpenDataExportHelper
  def self.transmit_not_for_publication_file(data:, type_of_export:, bucket_name:)
    filename =
      if type_of_export == "for_odc"
        "open_data_export_not_for_publication_#{Time.now.utc.strftime('%F')}.csv"
      else
        "test/open_data_export_not_for_publication_#{Time.now.utc.strftime('%F')}.csv"
      end

    storage_config_reader = Gateway::StorageConfigurationReader.new(
      bucket_name:,
    )
    storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)
    storage_gateway.write_file(filename, data)
  end
end
