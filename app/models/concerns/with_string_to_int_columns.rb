module WithStringToIntColumns
  extend ActiveSupport::Concern

  class_methods do
    include SetterOverrideMixin
    def string_to_int_columns(*cols)
      cols.each do |col|
        safe_override_setter(col, 'string_to_int') do |val|
          if val.is_a?(String)
            val.delete(',')
          else
            val
          end
        end
      end
    end
  end
end
