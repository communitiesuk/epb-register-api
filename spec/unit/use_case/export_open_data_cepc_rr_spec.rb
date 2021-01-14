describe UseCase::ExportOpenDataCepcrr do
  include RSpecRegisterApiServiceMixin
  context "when creating the open data reporting release" do
    describe "for the DEC reccomemdation reports" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:expected) { described_class.new }
      let(:date_today) { DateTime.now.strftime("%F") }
      let(:time_today) { DateTime.now.strftime("%F %H:%M:%S") }
      let(:number_assessments_to_test) { 1 }
      let(:non_domestic_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc+rr") }

      let(:expected_values) do
        Samples::ViewModels::Dec.report_test_hash.merge(
          { lodgement_date: date_today, lodgement_datetime: time_today },
          )
      end

      it 'should be valid class' do
        expect(described_class).to eq(UseCase::ExportOpenDataCepcrr)
      end



    end
  end
end

