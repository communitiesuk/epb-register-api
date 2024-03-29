require "csv"

namespace :oneoff do
  namespace :address_matching do
    desc "Get all RRNs to UPRNs from RRN to LPRN and Ordinance Survey LPRN2UPRN"
    # This is an early hacked-together version of getting data together for the
    # import_address_matching task
    task :rrn2uprn do
      Tasks::TaskHelpers.quit_if_production
      lprn2rrn = {}

      i = 0

      CSV.foreach(ENV["rrn2lprn"], "r", { col_sep: "\t" }) do |row|
        if row[1].start_with?("LPRN-")
          lprn = row[1][5..].to_i.to_s

          unless lprn2rrn.key?(lprn)
            lprn2rrn[lprn] = []
          end
          lprn2rrn[lprn].push(row[0])
        end

        i += 1

        if (i % 100_000).zero?
          puts "Another hundred thousand!"
        end
      end

      puts "Number of LPRNs matched: ", lprn2rrn.size

      output_file = File.open(ENV["output_file"], "w")

      CSV.foreach(ENV["uprn2lprn"], "r") do |row|
        if lprn2rrn.key?(row[2])
          lprn2rrn[row[2]].each do |rrn|
            output_file.write("#{rrn}, UPRN-#{row[1].rjust(12, '0')}, os_lprn2uprn\n")
          end

          lprn2rrn.delete(row[2])
        end

        i += 1

        if (i % 100_000).zero?
          puts "Another hundred thousand!"
        end
      end
    end

    desc "Merge two CSVs together, but not overwriting the primary key of the former CSV"

    task :merge_csv do
      Tasks::TaskHelpers.quit_if_production
      done = {}

      i = 0

      CSV.foreach(ENV["output_file"], "r") do |row|
        done[row[0]] = true

        i += 1

        if (i % 100_000).zero?
          puts "Another hundred thousand indexed!"
        end
      end

      puts done.length

      output_file = File.open(ENV["output_file"], "a")

      i = 0
      added = 0

      CSV.foreach(ENV["insert"], "r", { col_sep: "\t" }) do |row|
        unless done[row[0]]
          output_file.write("#{row[0]}, #{ENV['prefix'] + row[1]}, #{ENV['name']}\n")

          done[row[0]] = true

          added += 1
        end

        i += 1

        if (i % 100_000).zero?
          puts "Another hundred thousand!"
        end
      end

      puts "Added ", added
      puts "Out of a total of ", i
    end
  end
end
