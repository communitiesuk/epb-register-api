class SchemesGatewaySpy
  def add(*)
    @add_was_called = true
  end

  def add_was_called?
    @add_was_called
  end
end
