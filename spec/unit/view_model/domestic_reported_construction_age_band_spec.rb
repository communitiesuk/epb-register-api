describe "ViewModel::Domestic::ConstructionAgeBand" do
  context "when calling construction-age-band method on a domestic view model" do
    {
      'SAP-Schema-18.0.0': {
        epc: %w[A B C D E F G H I J K L],
      },
      'SAP-Schema-17.1': {
        epc: %w[A B C D E F G H I J K L],
      },
      'SAP-Schema-17.0': {
        epc: %w[A B C D E F G H I J K L],
      },
      'SAP-Schema-16.3': {
        sap: %w[A B C D E F G H I J K],
        rdsap: %w[A B C D E F G H I J K L 0 NR],
      },
    }.each do |schema, types|
      types.each do |type, bands|
        context "when schema is #{schema} and type is #{type}" do
          bands.each do |band|
            it "returns the band #{band}" do
              xml = Nokogiri.XML Samples.xml(schema, type)
              building_part_number_node_set =
                xml.xpath("//*[local-name() = 'Building-Part-Number']")
              building_part_parent =
                building_part_number_node_set.select { |node|
                  node.content == "1"
                }.first.parent
              building_part_parent
                .xpath("//*[local-name() = 'Construction-Age-Band']")
                .map(&:remove)
              building_part_parent.add_child "<Construction-Age-Band>#{band}</Construction-Age-Band>"

              wrapper =
                ViewModel::Factory.new.create(xml.to_s, schema.to_s, nil)
              view_model = wrapper.get_view_model

              expect(view_model.construction_age_band).to eq(band)
            end
          end
        end
      end
    end
  end
end
