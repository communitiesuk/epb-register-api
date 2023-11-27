class MockGateway
  include Gateway::ReadOnlyDatabaseAccess

  def run_read_only(&block)
    read_only(&block)
  end
end

describe "use read only connection using ActiveRecord support" do
  subject(:accessor) { MockGateway.new }

  uprn = "555111000555"

  before do
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("STAGE").and_return "TEST_READER"
    Helper::Toggles.set_feature("register-api-use-reader-connection", true)
    add_address_base uprn:, postcode: "SW1A 1AA", country_code: "E"
  end

  after do
    Helper::Toggles.set_feature("register-api-use-reader-connection", false)
  end

  it "is able to access database on a read-only connection that does not share current transaction" do
    expect(
      ActiveRecord::Base.connection.exec_query(
        "SELECT * FROM address_base WHERE uprn = '#{uprn}'",
      ).count,
    ).to eq 1
    # We expect that a different connection will be successfully opted into here
    # which does not have access to transaction in which this UPRN will have
    # already been written into the database.
    expect(
      accessor.run_read_only {
        ActiveRecord::Base.connection.exec_query(
          "SELECT * FROM address_base WHERE uprn = '#{uprn}'",
        )
      }.count,
    ).to eq 0
  end
end
