module ActiveAdmin
  module Inputs
    class FileInput < ::Formtastic::Inputs::FileInput
      def to_html
        input_wrapping do
          input_html_options[:class].remove!('form-control') if input_html_options[:class].include?('form-control')
          label_html <<
            builder.file_field(method, input_html_options)
        end
      end
    end
  end
end