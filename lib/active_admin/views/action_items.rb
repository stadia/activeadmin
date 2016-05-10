module ActiveAdmin
  module Views

    class ActionItems < ActiveAdmin::Component

      def build(action_items)
        add_class 'row'
        div class: 'col-md-12' do
          action_items.each do |action_item|
            span class: 'action_item pull-right' do
              instance_exec(&action_item.block)
            end
          end
        end
      end

    end

  end
end
