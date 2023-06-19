describe "bulk insert search address rake" do
  let(:bulk_insert_search_address_rake) { get_task("oneoff:bulk_insert_search_address") }

  let(:bulk_insert_search_address_use_case) { instance_double(UseCase::BulkInsertSearchAddress) }

  before do
    allow($stdout).to receive(:puts)
    allow(bulk_insert_search_address_use_case).to receive(:execute)
    allow(ApiFactory).to receive(:bulk_insert_search_address_use_case).and_return(bulk_insert_search_address_use_case)
  end

  it "calls the use case" do
    bulk_insert_search_address_rake.invoke
    expect(bulk_insert_search_address_use_case).to have_received(:execute).exactly(1).times
  end
end
