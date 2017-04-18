module ActiveAdmin
  module Views

    class SiteTitle < Component

      def tag_name
        'div'
      end

      def build(namespace)
        super(id: "site_title")
        @namespace = namespace

        button class: 'navbar-toggle', 'data-toggle' => 'collapse', 'data-target' => '.navbar-collapse', type: 'button' do
          span class: 'sr-only' do
            text_node 'Toggle navigation'
          end
          span class: 'icon-bar'
          span class: 'icon-bar'
          span class: 'icon-bar'
        end

        text_node site_title_with_link
      end

      def site_title_link?
        @namespace.site_title_link.present?
      end

      def site_title_image?
        @namespace.site_title_image.present?
      end

      protected

      # By default, add a css class named after the ruby class
      def default_class_name
        'navbar-header'
      end

      private

      def site_title_with_link
        helpers.link_to(site_title_content, @namespace.site_title_link, class: 'navbar-brand')
      end

      def site_title_content
        if site_title_image?
          title_image
        else
          title_text
        end
      end

      def title_text
        helpers.render_or_call_method_or_proc_on(helpers, @namespace.site_title)
      end

      def title_image
        path = helpers.render_or_call_method_or_proc_on(helpers, @namespace.site_title_image)
        helpers.image_tag(path, id: "site_title_image", alt: title_text, class: 'navbar-brand')
      end

    end

  end
end
