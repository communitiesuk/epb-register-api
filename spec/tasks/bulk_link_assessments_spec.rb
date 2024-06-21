describe "bulk link assessments rake" do
  include RSpecRegisterApiServiceMixin

  let(:bulk_link_assessments) { get_task("maintenance:bulk_link_assessments") }
  let(:bulk_link_assessments_use_case) { instance_double(UseCase::BulkLinkAssessments) }

  before do
    allow(ApiFactory).to receive(:bulk_link_assessments_use_case).and_return(bulk_link_assessments_use_case)
    allow(bulk_link_assessments_use_case).to receive(:execute)
  end

  it "calls the use case" do
    bulk_link_assessments.invoke
    expect(bulk_link_assessments_use_case).to have_received(:execute)
  end
end
