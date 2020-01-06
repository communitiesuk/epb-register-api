class TogglesStub
  def toggles; end

  def state(name)
    name == 'a'
  end
end
