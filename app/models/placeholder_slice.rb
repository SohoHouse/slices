class PlaceholderSlice < Slice
  restricted_slice

  def render
    renderer.render_container(container, current_page.ordered_slices)
  end
end
