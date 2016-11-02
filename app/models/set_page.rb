class SetPage < Page
  has_slices :set_slices

  def entry_types
    sets.map(&:entry_type)
  end

  def entries(type)
    children.criteria.where(_type: type.to_s.classify)
  end
end
