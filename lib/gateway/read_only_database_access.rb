module Gateway
  # A module which provides a wrapper method within which any database access will
  # use a reader connection. This is intended for reads that are likely to be a little
  # heavier than others, so that deploy targets are able to use read-only connections
  # that may be load-balanced across database instances (rather than just hitting a
  # writer instance). Under a test context, this is a no-op because of the difficulty
  # in testing database access across different connections when tests use isolated
  # transactions.
  module ReadOnlyDatabaseAccess
    def read_only(&block)
      if ENV["STAGE"] == "test" || !Helper::Toggles.enabled?("register-api-use-reader-connection")
        return yield block
      end

      ActiveRecord::Base.connected_to(role: :reading) do
        yield block
      end
    end
  end
end
