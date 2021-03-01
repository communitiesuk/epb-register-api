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

      title = [
        xpath(%w[Improvement-Heading], node),
        xpath(%w[Improvement-Summary], node),
        xpath(%w[Improvement], node),
      ].compact.delete_if(&:empty?).first || ""

      title = "" if title.to_i.to_s == title

      title
    end
  end
end
