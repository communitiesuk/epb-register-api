# frozen_string_literal: true

describe ActiveRecord::Base do
  def connect(database_name)
    ENV['RACK_ENV'] = database_name.remove('epb_')

    described_class.connection
  end

  def migration_has_been_run?(version)
    table_name = ActiveRecord::SchemaMigration.table_name

    query =
      "SELECT version FROM %s WHERE version = '%s'" % [table_name, version]
    described_class.connection.execute(query).any?
  end

  it 'can connect to an existing database' do
    connect('epb_test')

    expect(described_class.connected?).to be true
  end

  it 'has run the create schemes migration' do
    connect('epb_development')

    expect(migration_has_been_run?('20191120133528')).to be true
  end

  it 'has run the add unique index to scheme name migration' do
    connect('epb_development')

    expect(migration_has_been_run?('20191127191652')).to be true
  end

  it 'has run the create assessors migration' do
    connect('epb_development')

    expect(migration_has_been_run?('20191203162034')).to be true
  end

  it 'has run the add assessor contact details migration' do
    connect('epb_development')

    expect(migration_has_been_run?('20191212150246')).to be true
  end

  it 'can find the schemes table' do
    connect('epb_development')

    ActiveRecord::Base.establish_connection

    expect(described_class.connection.table_exists?('schemes')).to be true
  end

  it 'can find the scheme_id column' do
    connect('epb_development')

    described_class.establish_connection

    scheme_id =
      described_class.connection.execute('SELECT scheme_id FROM schemes')

    expect(scheme_id).not_to be_nil
  end
end
