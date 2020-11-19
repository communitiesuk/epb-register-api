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
    s3_bucket_configs = vcap['VCAP_SERVICES']['aws-s3-bucket']
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
    created_at = '2019-09-24 20:10:58.977914' # csv_line[2]

    ActiveRecord::Base.connection.execute("INSERT INTO lprn_to_rrn VALUES ('#{lprn}', '#{rrn}', '#{created_at}')"\
    " ON CONFLICT ON CONSTRAINT lprn_to_rrn_pkey DO UPDATE SET rrn = EXCLUDED.rrn, created_at = EXCLUDED.created_at ;")
  end

end
