require 'json'
require 'csv'
require 'aws-sdk-s3'

desc 'Import address matching data from an S3 bucket'

task :import_address_matching do
  if ENV['bucket_name'].nil?
    abort('Please set the bucket_name environment variable') if ENV['bucket_name'].nil?
  end
  if ENV['file_name'].nil?
    abort('Please set the file_name environment variable') if ENV['file_name'].nil?
  end

  if ENV['VCAP_SERVICES'].nil?
    puts "No VCAP_SERVICES environment variable found, using local credentials"
    s3_client = Aws::S3::Client::new
  else
    vcap = JSON.parse(ENV['VCAP_SERVICES'])
    s3_bucket_configs = vcap['aws-s3-bucket']
    s3_bucket_config = s3_bucket_configs.detect { |bucket| bucket['credentials']['bucket_name'] == ENV['bucket_name']}
    aws_credentials = Aws::Credentials::new(s3_bucket_config['credentials']['aws_access_key_id'], s3_bucket_config['credentials']['aws_secret_access_key'])
    s3_client = Aws::S3::Client::new(region: s3_bucket_config['credentials']['aws_region'], credentials: aws_credentials)
  end

  file_response = s3_client.get_object(bucket: ENV['bucket_name'], key: ENV['file_name'])
  file_content = file_response.body.string
  csv_contents = CSV.parse(file_content)
  puts "Size of CSV is #{csv_contents.size}, read at #{Time.now}"

  csv_contents.each do |csv_line|
    lprn = csv_line[0]
    rrn = csv_line[1]

    ActiveRecord::Base.connection.execute("INSERT INTO assessments_address_id_backup " \
    "SELECT aa.* FROM assessments_address_id aa " \
    "INNER JOIN assessments a USING (assessment_id) " \
    "WHERE a.address_id = '#{lprn}' AND aa.source = 'lprn_without_os_uprn'")

    ActiveRecord::Base.connection.execute("UPDATE assessments_address_id " \
    "SET address_id = '#{rrn}' " \
    "WHERE assessment_id IN (SELECT assessment_id from assessments WHERE address_id = '#{lprn}') " \
    "AND source = 'lprn_without_os_uprn'")
  end
  puts "Finished processing CSV file at #{Time.now}"

end
