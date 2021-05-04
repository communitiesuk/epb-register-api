module ViewModel::Export
  class CommercialExportView < ViewModel::Export::ExportBaseView
    def build
      { address: address }
    end
  end
end
