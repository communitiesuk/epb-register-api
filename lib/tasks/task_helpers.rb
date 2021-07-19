module Tasks
  class TaskHelpers
    def self.quit_if_production
      unless ENV["STAGE"].nil?
        unless  %w[test development integration staging].include? ENV["STAGE"]
          raise StandardError, "This task can only be run if the STAGE is test, development, integration or staging"
        end
      end
    end
  end
end
