module ActiveAdamin
  module Inputs
    class BooleanInput < ::Formtastic::Inputs::BooleanInput
      def to_html
        input_wrapping do
          '<div class="checkbox">'.html_safe << hidden_field_html << label_with_nested_checkbox << '</div>'.html_safe
        end
      end

      def input_html_options
        super[:class].remove!('form-control') if super[:class].include?('form-control')
        { name: input_html_options_name }.merge(super)
      end
    end
  end
end
