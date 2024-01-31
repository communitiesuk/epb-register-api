namespace :oneoff do
  desc "Update created_at dates of assessments from Landmark data via csv"
  task :update_assessments_from_landmark do
    bucket_name = ENV["LANDMARK_BUCKET"]
    file_name   = ENV["FILE_NAME"]
    raise Boundary::ArgumentMissing, "file_name" unless file_name

    use_case = ApiFactory.update_assessments_from_landmark(bucket_name:)
    num_rows = use_case.execute(file_name:)

    puts "#{num_rows} assessments have been updated"
  end
end
