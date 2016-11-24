class PreparedSlice < Slice
  attr_reader :prepared

  def prepare(_params)
    @prepared = true
  end
end
