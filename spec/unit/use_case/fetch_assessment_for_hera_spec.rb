describe UseCase::FetchAssessmentForHera do
  subject(:use_case) { described_class.new(domestic_digest_gateway:, summary_use_case:) }

  let(:domestic_digest_gateway) { instance_double Gateway::DomesticDigestGateway }

  let(:summary_use_case) { instance_double UseCase::AssessmentSummary::Fetch }

  context "when an RRN matches an RdSAP assessment for which HERA details can be provided" do
    rrn = "0000-1111-2222-3333-4444"
    xml = Samples.xml "RdSAP-Schema-20.0.0"

    before do
      allow(domestic_digest_gateway).to receive(:fetch_by_rrn).with(rrn).and_return({
        "xml" => xml,
        "schema_type" => "RdSAP-Schema-20.0.0",
      })
      allow(summary_use_case).to receive(:execute).with(rrn).and_return({
        superseded_by: nil,
      })
    end

    it "returns a domain object containing the expected HERA details", :aggregate_failures do
      details = use_case.execute(rrn:)
      expect(details).to be_a Domain::AssessmentHeraDetails
    end
  end

  context "when an RRN does not match an assessment for which HERA details can be provided" do
    rrn = "5555-5555-5555-5555-5555"

    before do
      allow(domestic_digest_gateway).to receive(:fetch_by_rrn).with(rrn).and_return(nil)
    end

    it "returns nil" do
      expect(use_case.execute(rrn:)).to be_nil
    end
  end
end
