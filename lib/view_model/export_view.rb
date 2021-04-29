module ViewModel
  class ExportView
    def initialize(certificate_wrapper)
      @view_model = certificate_wrapper.get_view_model
    end

    def build
      {
        addendum: @view_model.addendum,
        address_id: @view_model.address_id,
        address_line1: @view_model.address_line1,
        address_line2: @view_model.address_line2,
        address_line3: @view_model.address_line3,
        address_line4:
          if @view_model.respond_to?(:address_line4)
            @view_model.address_line4
          end,
        postcode: @view_model.postcode,
        town: @view_model.town,
      }
    end
  end
end
