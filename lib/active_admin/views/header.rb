module ActiveAdmin
  module Views
    class Header < Component

      def build(namespace, menu)
        super(id: "header", role: "navigation", style: "margin-bottom: 0")
        add_class "navbar navbar-default navbar-static-top"

        @namespace = namespace
        @menu = menu
        @utility_menu = @namespace.fetch_menu(:utility_navigation)

        div class: "container-fluid" do
          site_title @namespace
          utility_navigation @utility_menu, id: "utility_nav", class: "nav navbar-top-links navbar-right"
          div class: "navbar-default sidebar", role: "navigation" do
            div class: "sidebar-nav navbar-collapse" do
              global_navigation @menu, class: 'header-item tabs nav', id: "side-menu"
            end
          end
        end
      end

    end
  end
end
