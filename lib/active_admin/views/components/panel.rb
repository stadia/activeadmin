# frozen_string_literal: true
module ActiveAdmin
  module Views

    class Panel < ActiveAdmin::Component
      builder_method :panel

      def build(title, attributes = {})
        super(attributes)
        add_class "panel panel-default"
        @title = div(title.to_s, class: 'panel-heading')
        @contents = div(class: "panel_contents panel-body")
      end

      def add_child(child)
        if @contents
          @contents << child
        else
          super
        end
      end

      # Override children? to only report children when the panel's
      # contents have been added to. This ensures that the panel
      # correcly appends string values, etc.
      def children?
        @contents.children?
      end

      def header_action(*args)
        action = args[0]

        @title << div(class: "header_action") do
          action
        end
      end
    end
  end
end
