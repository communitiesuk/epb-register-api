module PostcodeHelper
  def self.check_task_requirements(file_name:, bucket_name:)
    if bucket_name.nil?
      raise Boundary::ArgumentMissing, "bucket_name"
    end
    if file_name.nil?
      raise Boundary::ArgumentMissing, "file_name"
    end

    unless file_name.start_with?("NSPL")
      raise Boundary::InvalidArgument, "file name #{file_name} must start with 'NSPL'"
    end
  end

  def self.retrieve_file_on_s3(file_name:, bucket_name:)
    storage_gateway = ApiFactory.storage_gateway(bucket_name:)

    puts "[#{Time.now}] Retrieving from S3 file: #{file_name}"
    storage_gateway.get_file_io(file_name)
  end
end
