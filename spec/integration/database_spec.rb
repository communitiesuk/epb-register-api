# frozen_string_literal: true

require 'sinatra/activerecord'
require 'dotenv'

describe ActiveRecord::Base do
  before do
    described_class.establish_connection(
      adapter: 'postgresql',
      database: 'epb_development',
      host: '127.0.0.1',
      username: 'postgres',
      password: ENV['DOCKER_POSTGRES_PASSWORD']
    )
  end

  it 'can connect to an existing database' do
    described_class.connection

    expect(described_class.connected?).to be_truthy
  end
end
