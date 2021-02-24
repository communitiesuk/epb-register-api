module ViewModel
  class DomesticEpcViewModel < ViewModel::BaseViewModel
    def initialize(xml)
      super(xml)
    end

    def improvement_title(node)
      # The SAP and RdSAP XSDs say
      # Text to precede the improvement description.
      # If 'Improvement-Heading' is not provided the 'Improvement-Summary' is used instead.
      return "" unless node

      heading = xpath(%w[Improvement-Heading], node)
      summary = xpath(%w[Improvement-Summary], node)
      if heading.nil? || heading.empty?
        summary || ""
      else
        heading
      end
    end
  end
end
