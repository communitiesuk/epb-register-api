module Helper
  class ClassHelper
    def self.method_or_nil(adapter, method)
      adapter.send(method)
    rescue NoMethodError
      nil
    end
  end
end
