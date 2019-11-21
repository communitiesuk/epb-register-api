# frozen_string_literal: true

require 'sinatra/activerecord'
require 'dotenv'

describe ActiveRecord::Base do
  before do
    described_class.establish_connection
  end

  it 'can connect to an existing database' do
    described_class.connection

    expect(described_class.connected?).to be_truthy
  end

  it 'can find the schemes table' do
    ENV['RACK_ENV'] = 'development'
    described_class.connection
  end
end
