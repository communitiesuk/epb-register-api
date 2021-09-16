module AddressMatchingHelper
  def self.process_address_matching_csv(csv_content, counter:)
    while (csv_row = csv_content.shift)
      update_address_from_csv_row csv_row, counter: counter

      if (counter.processed % 100_000).zero?
        puts "[#{Time.now}] Processed #{counter.processed} LPRNs from CSV file, skipped #{counter.skipped} present in backup table"
      end
    end
  end

  def self.update_address_from_csv_row(csv_row, counter:)
    counter.processed += 1

    lprn = csv_row["lprn"]
    # Only present when matching LPRN -> UPRN
    uprn = csv_row["uprn"]
    # Only present when matching LPRN -> RRN
    rrn = csv_row["rrn"]

    if rrn.nil?
      new_address_id = uprn
      source = "os_lprn2uprn"
    else
      new_address_id = rrn
      source = "lprn_without_os_uprn"
    end

    db = ActiveRecord::Base.connection
    existing_backup = db.exec_query(
      "SELECT 1 FROM assessments_address_id_backup aab " \
          "INNER JOIN assessments a USING (assessment_id) " \
          "WHERE a.address_id = '#{lprn}'",
    )

    if existing_backup.empty?
      ActiveRecord::Base.transaction do
        db.exec_query(
          "INSERT INTO assessments_address_id_backup " \
              "SELECT aai.* FROM assessments_address_id aai " \
              "INNER JOIN assessments a USING (assessment_id) " \
              "WHERE a.address_id = '#{lprn}' " \
              "AND aai.source != 'epb_team_update' " \
              "AND aai.address_id NOT LIKE 'UPRN-%' " \
              "AND aai.address_id != '#{new_address_id}'",
        )

        db.exec_query(
          "UPDATE assessments_address_id " \
              "SET address_id = '#{new_address_id}', source = '#{source}' " \
              "WHERE assessment_id IN (SELECT assessment_id from assessments a " \
                "INNER JOIN assessments_address_id aai USING (assessment_id) " \
                "WHERE a.address_id = '#{lprn}' " \
                "AND aai.source != 'epb_team_update' " \
                "AND aai.address_id NOT LIKE 'UPRN-%' " \
                "AND aai.address_id != '#{new_address_id}')",
        )
      end
    else
      counter.skipped += 1
    end
  end

  def self.check_address_matching_requirements(env:)
    if env["bucket_name"].nil? && env["instance_name"].nil?
      abort("Please set the bucket_name or instance_name environment variable")
    end
    if env["file_name"].nil?
      abort("Please set the file_name environment variable")
    end
  end

  def self.bind_string_attribute(array, name, value)
    array << ActiveRecord::Relation::QueryAttribute.new(name, value, ActiveRecord::Type::String.new)
  end

  class Counter
    attr_accessor :processed, :skipped

    def initialize(processed:, skipped:)
      @processed = processed
      @skipped = skipped
    end
  end
end
