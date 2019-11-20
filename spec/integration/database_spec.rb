# frozen_string_literal: true

require 'sinatra/activerecord'

describe ActiveRecord::Base do
  before do
    described_class.establish_connection(
      adapter: 'postgresql',
      database: 'epb_development'
    )
  end

  it 'can connect to an existing database' do
    described_class.connection

    expect(described_class.connected?).to be_truthy
  end
end
