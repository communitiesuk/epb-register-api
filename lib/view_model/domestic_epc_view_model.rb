module ViewModel
  class DomesticEpcViewModel < ViewModel::BaseViewModel
    def initialize(xml)
      super(xml)
    end

    def improvement_title(node)
      # The SAP and RdSAP XSDs say
      # Text to precede the improvement description.
      # If 'Improvement-Heading' is not provided the 'Improvement-Summary' is used instead
      # If 'Improvement-Summary' is not provided the 'Improvement' is used instead
      return "" unless node

      title =
        [
          xpath(%w[Improvement-Heading], node),
          xpath(%w[Improvement-Summary], node),
          xpath(%w[Improvement], node),
        ].compact.delete_if(&:empty?).first || ""

      title = "" if title.to_i.to_s == title

      title
    end

    def property_type
      xpath(%w[Property-Type])
    end

    def multi_glazing_type
      xpath(%w[Multiple-Glazing-Type])
    end

    def addendum
      return nil if xpath(%w[Addendum]).nil?

      fetch_addendum_numbers.merge(fetch_addendum_boolean_nodes)
    end

    def lzc_energy_sources
      return nil if xpath(%w[LZC-Energy-Sources]).nil?

      @xml_doc
        .search("LZC-Energy-Sources/LZC-Energy-Source")
        .select(&:element?)
        .map { |n| n.text.to_i }
    end

  private

    def fetch_addendum_numbers
      return {} if @xml_doc.search("Addendum/Addendum-Number").empty?

      {
        addendum_number:
          @xml_doc
            .search("Addendum/Addendum-Number")
            .select(&:element?)
            .map { |n| n.text.to_i },
      }
    end

    def fetch_addendum_boolean_nodes
      nodes_array =
        @xml_doc
          .search("Addendum")
          .select(&:element?)
          .first
          .children
          .select do |child|
            child.name != "Addendum-Number" && child.name != "text"
          end

      if nodes_array.empty?
        {}
      else
        nodes_array.map { |node|
          [
            node.name.underscore.to_sym,
            ActiveRecord::Type::Boolean.new.cast(node.children.text),
          ]
        }.to_h
      end
    end
  end
end
