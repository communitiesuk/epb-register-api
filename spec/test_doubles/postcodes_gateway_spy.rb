class PostcodesGatewaySpy
  def fetch(*)
    @fetch_was_called = true
  end

  def fetch_was_called?
    @fetch_was_called
  end
end
