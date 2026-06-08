describe UseCase::FetchDecSummary do
  subject(:use_case) do
    described_class.new
  end

  let(:assessments_xml_gateway) { instance_double Gateway::AssessmentsXmlGateway }
  let(:assessment_gateway) { instance_double Gateway::AssessmentsSearchGateway }
  let(:args) { { address_id: "RRN-0000-0000-0000-0000-0000", type_of_assessment: "DEC", assessment_id: "0000-0000-0000-0000-0000", address_line1: "Non-dom Property", address_line2: "Buisness Park", address_line3: "", address_line4: "", town: "Town", created_at: Time.utc(2022, 9, 1, 6, 0, 0), date_of_assessment: "2023-06-27", date_of_expiry: "2026-03-18", date_registered: "2023-06-27", current_energy_efficiency_rating: 0, opt_out: false, postcode: "EH14 2SP", scheme_assessor_id: "SPEC000000" } }
  let(:domain_object) { Domain::AssessmentSearchResult.new(**args) }

  let(:valid_dec_xml) { Samples.xml "CEPC-8.0.0", "dec" }
  let(:valid_scottish_dec_xml) { Samples.xml "DECAR-S-7.0", "dec" }

  before do
    allow(Gateway::AssessmentsSearchGateway).to receive(:new).and_return(assessment_gateway)
    allow(Gateway::AssessmentsXmlGateway).to receive(:new).and_return(assessments_xml_gateway)
  end

  context "when an assessment id matches an assessment" do
    assessment_id = "0000-1111-2222-3333-4444"

    before do
      allow(assessments_xml_gateway).to receive(:fetch).and_return({ xml: valid_dec_xml, schema_type: "CEPC-8.0.0" })
      allow(assessment_gateway).to receive(:search_by_assessment_id).and_return([domain_object])
      use_case.execute(assessment_id, is_scottish: false)
    end

    it "searches for the assessment" do
      expect(assessment_gateway).to have_received(:search_by_assessment_id).with(assessment_id, restrictive: false, is_scottish: false)
    end

    it "calls the assessment xml gateway" do
      expect(assessments_xml_gateway).to have_received(:fetch).with(assessment_id, is_scottish: false)
    end

    it "returns a dec summary xml", :aggregate_failures do
      details = use_case.execute(assessment_id, is_scottish: false)
      xml = Nokogiri.XML(details)
      expect(xml.at("UPRN").content).to eq("UPRN-000000000001")
    end
  end

  context "when an assessment is not found in the assessments table" do
    assessment_id = "5555-5555-5555-5555-5555"

    before do
      allow(assessment_gateway).to receive(:search_by_assessment_id).with(assessment_id, restrictive: false, is_scottish: false).and_return([])
    end

    it "raises a not found exception" do
      expect { use_case.execute(assessment_id, is_scottish: false) }.to raise_error(described_class::AssessmentNotFound)
    end
  end

  context "when an assessment is cancelled or not for issue" do
    assessment_id = "5555-4444-3333-2222-1111"

    before do
      args[:cancelled_at] = Time.utc(2023, 8, 4, 6, 0, 0)
      allow(assessment_gateway).to receive(:search_by_assessment_id).with(assessment_id, restrictive: false, is_scottish: false).and_return([Domain::AssessmentSearchResult.new(**args)])
    end

    it "raises a assessment gone exception" do
      expect { use_case.execute(assessment_id, is_scottish: false) }.to raise_error(described_class::AssessmentGone)
    end
  end

  context "when an assessment is not a DEC" do
    assessment_id = "1111-2222-3333-2222-1111"

    let(:domain) do
      Domain::AssessmentSearchResult.new(address_id: "RRN-0000-0000-0000-0000-0000", type_of_assessment: "CEPC", assessment_id: "0000-0000-0000-0000-0000", address_line1: "Non-dom Property", address_line2: "Buisness Park", address_line3: "", address_line4: "", town: "Town", created_at: Time.utc(2022, 9, 1, 6, 0, 0), date_of_assessment: "2023-06-27", date_of_expiry: "2026-03-18", date_registered: "2023-06-27", current_energy_efficiency_rating: 0, opt_out: false, postcode: "EH14 2SP", scheme_assessor_id: "SPEC000000")
    end

    before do
      args[:type_of_assessment] = "CEPC"
      allow(assessment_gateway).to receive(:search_by_assessment_id).with(assessment_id, restrictive: false, is_scottish: false).and_return([Domain::AssessmentSearchResult.new(**args)])
    end

    it "raises a assessment not dec exception" do
      expect { use_case.execute(assessment_id, is_scottish: false) }.to raise_error(described_class::AssessmentNotDec)
    end
  end

  context "when assessment xml is not found" do
    assessment_id = "5555-5555-5555-5555-5555"

    before do
      allow(assessment_gateway).to receive(:search_by_assessment_id).and_return([domain_object])
      allow(assessments_xml_gateway).to receive(:fetch).with(assessment_id, is_scottish: false).and_return(nil)
    end

    it "raises a not found exception" do
      expect { use_case.execute(assessment_id, is_scottish: false) }.to raise_error(described_class::AssessmentNotFound)
    end
  end

  context "when fetching a scottish DEC" do
    assessment_id = "1111-1111-5555-1111-5555"

    before do
      allow(assessments_xml_gateway).to receive(:fetch).and_return({ xml: valid_scottish_dec_xml, schema_type: "DECAR-S-7.0" })
      allow(assessment_gateway).to receive(:search_by_assessment_id).and_return([domain_object])
      use_case.execute(assessment_id, is_scottish: true)
    end

    it "searches for the assessment" do
      expect(assessment_gateway).to have_received(:search_by_assessment_id).with(assessment_id, restrictive: false, is_scottish: true)
    end

    it "calls the assessment xml gateway" do
      expect(assessments_xml_gateway).to have_received(:fetch).with(assessment_id, is_scottish: true)
    end
  end
end
