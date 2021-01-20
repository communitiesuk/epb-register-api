require 'rspec'
require 'aws-sdk-s3'

describe 'Gateway::StorageGateway' do

  context 'When storage is initialised' do
    before do
      @storage_gateway = Gateway::StorageGateway.new(
        storage_config: Gateway::StorageConfiguration.new(
          access_key_id: '',
          secret_access_key: '',
          bucket_name: 'my-bucket'
        ),
        stub_responses: true
      )
    end

    it 'retrieves an existing file' do
      stub_file_response(@storage_gateway.client)
      expect(@storage_gateway.get_file_io(file_name: 'my-file').string).to eq 'Hello!'
    end

    it 'fails when the file is not existing' do
      stub_file_response(@storage_gateway.client)
      expect(@storage_gateway.get_file_io(file_name: 'my-file').string).to eq 'Hello!'
    end
  end
end

def stub_file_response(client)
  client.stub_responses(:get_object, -> (context) {
    if context.params[:key] == 'my-file' && context.params[:bucket] == 'my-bucket'
      { body: 'Hello!' }
    else
      'NoSuchKey'
    end
  })
end
