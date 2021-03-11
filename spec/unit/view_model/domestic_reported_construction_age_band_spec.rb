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
        rdsap: %w[A B C D E F G H I J K 0 NR],
      },
      'SAP-Schema-16.2': {
        sap: %w[A B C D E F G H I J K],
        rdsap: %w[A B C D E F G H I J K 0 NR],
      },
      'SAP-Schema-16.1': {
        sap: %w[A B C D E F G H I J K],
        rdsap: %w[A B C D E F G H I J K 0 NR],
      },
    }.each do |schema, types|
      types.each do |type, bands|
        context "when schema is #{schema} and type is #{type}" do
          bands.each do |band|
            context "when the band is #{band}" do
              it "returns the band #{band}" do
                wrapper =
                  ViewModel::Factory.new.create(
                    prepare_sample_xml(schema, type, band).to_s,
                    schema.to_s,
                    nil,
                  )

                expect(wrapper.get_view_model.construction_age_band).to eq(band)
              end

              it "the band #{band} is valid for this schema" do
                schema_path = Helper::SchemaListHelper.new(schema).schema_path
                xsd =
                  Nokogiri::XML::Schema.from_document Nokogiri.XML(
                    File.read(schema_path),
                    schema_path,
                  )

                validation =
                  xsd.validate(prepare_sample_xml(schema, type, band))

                expect(validation).to be_empty, <<~ERROR
                  Failed on #{schema}:#{type}
                    This document does not validate against the chosen schema,
                      Errors:
                        #{validation.join("\n      ")}
                ERROR
              end
            end
          end
        end
      end
    end
  end
end

private

def prepare_sample_xml(schema, type, band)
  document = Nokogiri.XML Samples.xml(schema, type)

  building_part_number_node_set =
    document.xpath("//*[local-name() = 'Building-Part-Number']")

  building_part_number =
    building_part_number_node_set.select { |node| node.content == "1" }.first

  building_part = building_part_number.parent

  building_part
    .xpath("//*[local-name() = 'Construction-Age-Band']")
    .map { |n| n.remove if n.parent == building_part }

  building_part
    .xpath("//*[local-name() = 'Identifier']")
    .map { |n| n.remove if n.parent == building_part }

  building_part
    .xpath("//*[local-name() = 'Construction-Year']")
    .map { |n| n.remove if n.parent == building_part }

  namespace = building_part_number.namespace.prefix
  namespace = namespace ? namespace + ":" : ""

  building_part_number.add_next_sibling "<#{namespace}Construction-Age-Band>#{band}</#{namespace}Construction-Age-Band>"

  document
end
