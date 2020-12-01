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

  puts "Starting downloading CSV file #{ENV['file_name']} at #{Time.now}"
  file_response = s3_client.get_object(bucket: ENV['bucket_name'], key: ENV['file_name'])
  file_content = file_response.body.string
  csv_contents = CSV.parse(file_content)
  puts "Finished downloading CSV file, #{csv_contents.size} LPRNs to process"

  i = 0
  csv_contents.each do |csv_line|
    i += 1
    if i == 1
      puts "Starting processing CSV file at #{Time.now}"
    end
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

    i += 1
    if i % 10000 == 0
      puts "Processed #{i} LPRNs from CSV file at #{Time.now}"
    end
  end
  puts "Finished processing CSV file at #{Time.now}"

rescue StandardError => e
  puts "Error while downloading or processing CSV file: #{e}"
end
