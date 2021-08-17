require "nokogiri"
require_relative "../task_helpers.rb"

namespace :oneoff do
  # These tasks were used to backfill existing data when the linked assessments
  # table was first introduced
  desc "Ensures dual lodgements have the same address ID"
  task :linked_assessments_address_id do
    Tasks::TaskHelpers.quit_if_production
    puts "[#{Time.now}] Starting correcting linked assessment address IDs"

    ActiveRecord::Base.logger = nil
    db = ActiveRecord::Base.connection

    create_address_table_backup

    # Ensures the linked assessment is a recommendation report
    find_linked_assessments_sql = <<-SQL
      SELECT la.assessment_id, la.linked_assessment_id
      FROM linked_assessments la
      INNER JOIN assessments a ON la.linked_assessment_id = a.assessment_id
      WHERE a.type_of_assessment IN ('DEC-RR', 'CEPC-RR', 'AC-REPORT')
    SQL

    linked_assessments = db.exec_query find_linked_assessments_sql
    puts "[#{Time.now}] Found #{linked_assessments.length} linked assessments to process"

    changed = 0
    skipped = 0
    linked_assessments.each do |linked_assessment|
      assessment_id = linked_assessment["assessment_id"]
      linked_assessment_id = linked_assessment["linked_assessment_id"]

      find_different_address_id_sql = <<-SQL
        SELECT aai1.address_id
        FROM assessments_address_id aai1, assessments_address_id aai2
        WHERE aai1.address_id != aai2.address_id
        AND aai1.assessment_id = '#{assessment_id}'
        AND aai2.assessment_id = '#{linked_assessment_id}'
        AND aai2.source != 'epb_team_update'
      SQL

      different_address_id_match = db.exec_query find_different_address_id_sql

      if different_address_id_match.empty?
        skipped += 1
      else
        certificate_address_id = different_address_id_match.first["address_id"]

        backup_address_id = <<-SQL
          INSERT INTO assessments_address_id_backup
          SELECT * FROM assessments_address_id
          WHERE assessment_id = '#{linked_assessment_id}'
        SQL

        update_address_id = <<-SQL
          UPDATE assessments_address_id
          SET address_id = '#{certificate_address_id}'
          WHERE assessment_id = '#{linked_assessment_id}'
        SQL

        ActiveRecord::Base.transaction do
          db.exec_query backup_address_id
          db.exec_query update_address_id
        end
        changed += 1
      end
    end

    puts "[#{Time.now}] Finished correcting linked assessment address IDs, skipped:#{skipped} changed:#{changed}"
  end

  desc "Backfill linked assessments table from assessments XML"
  task :linked_assessments do
    Tasks::TaskHelpers.quit_if_production
    if ENV["from_date"].nil?
      abort("Please set the from_date environment variable")
    end

    puts "[#{Time.now}] Starting processing linked assessment"

    find_assessments_sql = <<-SQL
      SELECT a.assessment_id
      FROM assessments a
      LEFT JOIN linked_assessments la USING (assessment_id)
      WHERE a.date_registered >= #{ActiveRecord::Base.connection.quote(ENV['from_date'])}
      AND la.assessment_id IS NULL
    SQL

    assessment_types = []
    %w[DEC DEC-RR CEPC CEPC-RR AC-REPORT AC-CERT].each do |type|
      assessment_types.push(ActiveRecord::Base.connection.quote(type))
    end
    find_assessments_sql += " AND a.type_of_assessment IN(#{assessment_types.join(', ')})"

    assessments = ActiveRecord::Base.connection.exec_query find_assessments_sql
    puts "[#{Time.now}] Found #{assessments.length} assessments to process"

    inserted = 0
    skipped = 0
    assessments.each do |assessment|
      assessment_id = assessment["assessment_id"]
      assessment_xml = ActiveRecord::Base.connection.exec_query("SELECT xml, schema_type FROM assessments_xml WHERE assessment_id = '#{assessment_id}'").first
      if assessment_xml.nil?
        puts "[#{Time.now}] Could not read XML for assessment #{assessment_id}"
        skipped += 1
      else
        schema_type = assessment_xml["schema_type"]

        begin
          wrapper = ViewModel::Factory.new.create(assessment_xml["xml"], schema_type, assessment_id)
        rescue StandardError => e
          wrapper = nil
          skipped += 1
          puts "[#{Time.now}] Exception in view model creation for #{schema_type}, skipping #{assessment_id}"
          puts "[#{Time.now}] #{e.message}"
          puts "[#{Time.now}] #{e.backtrace.first}"
        end
        next if wrapper.nil?

        begin
          wrapper_hash = wrapper.to_hash
        rescue StandardError => e
          wrapper_hash = nil
          skipped += 1
          puts "[#{Time.now}] Exception in wrapper to_hash, skipping #{assessment_id}"
          puts "[#{Time.now}] #{e.message}"
          puts "[#{Time.now}] #{e.backtrace.first}"
        end
        next if wrapper_hash.nil?

        related_rrn = find_related_rrn(wrapper_hash)
        if related_rrn.nil?
          skipped += 1
        else
          ActiveRecord::Base.connection.exec_query("INSERT INTO linked_assessments VALUES('#{assessment_id}','#{related_rrn}')")
          inserted += 1
        end
      end
    end
    puts "[#{Time.now}] Finished processing linked assessment, skipped:#{skipped} inserted:#{inserted}"
  end

  def find_related_rrn(wrapper_hash)
    related_rrn = nil
    # related-rrn: AC-CERT AC-REPORT CEPC DEC-RR
    related_rrn = wrapper_hash[:related_rrn] unless wrapper_hash[:related_rrn].nil?
    # related_certificate: CEPC-RR
    related_rrn = wrapper_hash[:related_certificate] unless wrapper_hash[:related_certificate].nil?
    # administrative_information->related_rrn: DEC
    if related_rrn.nil? && !wrapper_hash.dig(:administrative_information, :related_rrn).nil?
      related_rrn = wrapper_hash[:administrative_information][:related_rrn]
    end
    related_rrn
  end
end
