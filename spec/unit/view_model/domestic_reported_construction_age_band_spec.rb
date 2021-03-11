describe "ViewModel::Domestic::ConstructionAgeBand" do
  context "when calling construction-age-band method from a view model for to_report" do
    {
        'SAP-Schema-18.0.0': {
            epc: %w[A B C D E F G H I J K]
        },
        'SAP-Schema-17.1': {
            epc: %w[A B C D E F G H I J K]
        },
        'SAP-Schema-17.0': {
            epc: %w[A B C D E F G H I J K]
        },
    }.each do |schema, types|
      types.each do |type, bands|
        bands.each do |band|

          context "for schema #{schema} and #{type}" do
            it "the fixture with value #{band} is valid" do
              xml = Nokogiri.XML Samples.xml(schema, type)
              building_part_number_node_set = xml.xpath("//*[local-name() = 'Building-Part-Number']")

              building_part_parent = building_part_number_node_set.select { |node| node.content == '1' }.first.parent
              building_part_parent.search("Construction-Age-Band").first&.remove
              building_part_parent.add_child "<Construction-Age-Band>#{band}</Construction-Age-Band>"

              wrapper = ViewModel::Factory.new.create(xml.to_s, schema.to_s, nil)
              view_model = wrapper.get_view_model

              expect(view_model.construction_age_band).to eq(band)
            end
          end
        end
      end
    end
  end
end
