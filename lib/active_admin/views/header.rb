module ActiveAdmin
  module Views
    class Header < Component

      def build(namespace, menu)
        super(id: "header", role: 'navigation', style: 'margin-bottom: 0')
        add_class 'navbar navbar-default navbar-static-top'

        @namespace = namespace
        @menu = menu
        @utility_menu = @namespace.fetch_menu(:utility_navigation)

        build_site_title
        build_utility_navigation
        div class: 'navbar-default sidebar', role: 'navigation' do
          div class: 'sidebar-nav navbar-collapse' do
            build_global_navigation
          end
        end
      end

      def build_site_title
        insert_tag view_factory.site_title, @namespace
      end

      def build_global_navigation
        insert_tag view_factory.global_navigation, @menu, class: 'header-item tabs nav in', id: 'side-menu'
      end

      def build_utility_navigation
        insert_tag view_factory.utility_navigation, @utility_menu, id: "utility_nav", class: 'nav navbar-top-links navbar-right'
      end

      def tag_name
        'nav'
      end

    end
  end
end
