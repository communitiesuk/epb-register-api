

describe "linked_dev_assessments rake" do

  include RSpecRegisterApiServiceMixin


  context 'call the rake task and extract the saved data' do
    before do
      allow(STDOUT).to receive(:puts)
      allow(STDOUT).to receive(:write)
      get_task("lodge_dev_assessments").invoke
    end

  before(:all) do

  end

  let!(:exported_data) {
    ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments")
  }

  let!(:exported_xml) {
    ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments_xml")
  }

  it 'should write the correct data to the database' do
    expect(exported_data.rows.length).to eq(6)
    expect(exported_data.first["type_of_assessment"]).to eq("CEPC")
  end

  it 'should load the xml from the factory' do
    expect{ UseCase::AssessmentSummary::Fetch.new.execute('0000-0000-0000-0000-0001')}.not_to raise_error
  end

  end

  context 'read cepc data from fixure' do
    let!(:xml_doc) {
      Nokogiri.XML Samples.xml "CEPC-8.0.0", "cepc+rr"
    }

    it 'should get the report type from the xpath used in the factory' do
      filter_results_for = '0000-0000-0000-0000-0000'
      filtered_results = xml_doc.remove_namespaces!.at("//*[RRN=\"#{filter_results_for}\"]/ancestor::Report")
      expect( xml_doc.at("//Energy-Assessor//Certificate-Number").text).to eq("SPEC000000")

      expect(filtered_results).not_to eq(nil)
    end
  end

  context 'read SAP data from fixure' do
    let!(:xml_doc) {
      Nokogiri.XML Samples.xml "SAP-Schema-18.0.0", "epc"
    }

    it 'should get the report type from the xpath used in the factory' do
      filter_results_for = '0000-0000-0000-0000-0000'
      xml_doc.remove_namespaces!
      expect(  xml_doc.at("//Certificate-Number").text ).to eq("SPEC000000")

    end
  end

end
