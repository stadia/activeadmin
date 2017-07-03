module ActiveAdmin
  module Views
    module Pages
      class Base < Arbre::HTML::Document

        def build(*args)
          super
          add_classes_to_body
          build_active_admin_head
          build_page
        end

        protected

        def build_head
          @head = head do
            meta :"http-equiv" => "Content-type", content: "text/html; charset=utf-8", charset: "utf-8"
            meta :"http-equiv" => "X-UA-Compatible", content: "IE=edge"
            meta :"name" => "viewport", content: "width=device-width, initial-scale=1"
          end
        end

        private

        delegate :active_admin_config, :controller, :params, to: :helpers

        def add_classes_to_body
          @body.add_class(params[:action])
          @body.add_class(params[:controller].tr('/', '_'))
          @body.add_class("active_admin")
          @body.add_class("logged_in")
          @body.add_class(active_admin_namespace.name.to_s + "_namespace")
        end

        def build_active_admin_head
          within @head do
            insert_tag Arbre::HTML::Title, [title, render_or_call_method_or_proc_on(self, active_admin_namespace.site_title)].compact.join(" | ")
            active_admin_application.stylesheets.each do |style, options|
              text_node stylesheet_link_tag(style, options).html_safe
            end

            active_admin_namespace.meta_tags.each do |name, content|
              text_node(tag(:meta, name: name, content: content))
            end

            active_admin_application.javascripts.each do |path|
              text_node(javascript_include_tag(path))
            end

            if active_admin_namespace.favicon
              text_node(favicon_link_tag(active_admin_namespace.favicon))
            end

            text_node csrf_meta_tag
          end
        end

        def build_page
          within @body do
            div id: "wrapper" do
              build_unsupported_browser
              build_header
              div id: "page-wrapper", class: "container-fluid" do
                build_title_bar
                build_page_content
              end
              # build_footer
            end
          end
        end

        def build_unsupported_browser
          if active_admin_namespace.unsupported_browser_matcher =~ controller.request.user_agent
            insert_tag view_factory.unsupported_browser
          end
        end

        def build_header
          insert_tag view_factory.header, active_admin_namespace, current_menu
        end

        def build_title_bar
          insert_tag view_factory.title_bar, title, action_items_for_action
        end

        def build_page_content
          build_flash_messages
          div id: "active_admin_content", class: (skip_sidebar? ? "without_sidebar row" : "with_sidebar row") do
            build_main_content_wrapper
            build_sidebar unless skip_sidebar?
          end
        end

        def build_flash_messages
          return if flash_messages.empty?

          div class: 'flashes row' do
            flash_messages.each do |type, message|
              div class: "flash flash_#{type} alert alert-dismissible col-xs-12", role: 'alert' do
                button class: 'close', 'data-dismiss' => 'alert', 'aria-label' => 'close', type: 'button' do
                  span 'x', 'aria-hidden' => 'true'
                end
                text_node message
              end
            end
          end
        end

        def build_main_content_wrapper
          div id: "main_content", class: (skip_sidebar? ? 'col-lg-12' : 'col-lg-10') do
            main_content
          end
        end

        def main_content
          I18n.t('active_admin.main_content', model: title).html_safe
        end

        def title
          self.class.name
        end

        # Set's the page title for the layout to render
        def set_page_title
          set_ivar_on_view "@page_title", title
        end

        # Returns the sidebar sections to render for the current action
        def sidebar_sections_for_action
          if active_admin_config && active_admin_config.sidebar_sections?
            active_admin_config.sidebar_sections_for(params[:action], self)
          else
            []
          end
        end

        def action_items_for_action
          if active_admin_config && active_admin_config.action_items?
            active_admin_config.action_items_for(params[:action], self)
          else
            []
          end
        end

        # Renders the sidebar
        def build_sidebar
          div id: "sidebar", class: 'col-lg-2' do
            sidebar_sections_for_action.collect do |section|
              sidebar_section(section)
            end
          end
        end

        def skip_sidebar?
          sidebar_sections_for_action.empty? || assigns[:skip_sidebar] == true
        end

        # Renders the content for the footer
        def build_footer
          insert_tag view_factory.footer, active_admin_namespace
        end

      end
    end
  end
end
