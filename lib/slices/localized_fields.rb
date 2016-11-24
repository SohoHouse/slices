module Slices
  module LocalizedFields
    def localized_field_names
      fields.select { |_name, field| field.localized? }.map do |name, _field|
        name.to_sym
      end
    end
  end
end
