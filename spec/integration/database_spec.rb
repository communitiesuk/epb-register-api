# frozen_string_literal: true

require 'sinatra/activerecord'
require 'dotenv'

describe ActiveRecord::Base do
  def connect(database_name)
    ENV['RACK_ENV'] = if database_name == 'epb_development'
      'development'
    else
      'test'
    end

    described_class.connection
  end

  it 'can connect to an existing database' do
    connect('epb_test')

    expect(described_class.connected?).to be_truthy
  end

  it 'can find the schemes table' do
    connect('epb_development')

    ActiveRecord::Base.establish_connection

    expect(described_class.connection.table_exists?('schemes')).to eq(true)
  end

  it 'can find the scheme_id column' do
    connect('epb_development')

    ActiveRecord::Base.establish_connection

    schemes = ActiveRecord::Base.connection.execute('SELECT scheme_id FROM schemes')

    expect(schemes.to_a).to eq([])
  end
end
