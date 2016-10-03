module ActiveAdmin
  # CSVBuilder stores CSV configuration
  #
  # Usage example:
  #
  #   csv_builder = CSVBuilder.new
  #   csv_builder.column :id
  #   csv_builder.column("Name") { |resource| resource.full_name }
  #   csv_builder.column(:name, humanize_name: false)
  #   csv_builder.column("name", humanize_name: false) { |resource| resource.full_name }
  #
  #   csv_builder = CSVBuilder.new col_sep: ";"
  #   csv_builder = CSVBuilder.new humanize_name: false
  #   csv_builder.column :id
  #
  #
  class CSVBuilder

    # Return a default CSVBuilder for a resource
    # The CSVBuilder's columns would be Id followed by this
    # resource's content columns
    def self.default_for_resource(resource)
      new resource: resource do
        column :id
        resource.content_columns.each { |c| column c.name.to_sym }
      end
    end

    attr_reader :columns, :options, :paginate_with, :byte_order_mark, :column_names, :csv_options

    COLUMN_TRANSITIVE_OPTIONS = [:humanize_name].freeze

    def initialize(options={}, &block)
      @resource = options.delete(:resource)
      @block    = block
      @options  = ActiveAdmin.application.csv_options.merge options
      @paginate_with   = @options.delete(:paginate_with) { :find_each }
      @byte_order_mark = @options.delete :byte_order_mark
      @column_names    = @options.delete(:column_names) { true }
      @csv_options     = @options.except :encoding_options
    end

    def column(name, options={}, &block)
      @columns << Column.new(name, @resource, column_transitive_options.merge(options), block)
    end

    def build(controller, csv)
      @collection = controller.send :find_collection, except: :pagination
      columns     = exec_columns controller.view_context

      csv << encode(byte_order_mark) if byte_order_mark

      if column_names
        csv << CSV.generate_line(columns.map{ |c| encode c.name }, csv_options)
      end

      ActiveRecord::Base.uncached do
        each_resource do |resource|
          resource = controller.send :apply_decorator, resource
          csv << CSV.generate_line(build_row(resource, columns), csv_options)
        end
      end

      csv
    end

  private

    def exec_columns(view_context = nil)
      @view_context = view_context
      @columns = [] # we want to re-render these every instance
      instance_exec &@block if @block.present?
      @columns
    end

    def build_row(resource, columns)
      columns.map do |column|
        encode call_method_or_proc_on(resource, column.data)
      end
    end

    def encode(content)
      if options[:encoding]
        content.to_s.encode options[:encoding], options[:encoding_options]
      else
        content
      end
    end

    def method_missing(method, *args, &block)
      if @view_context.respond_to? method
        @view_context.public_send method, *args, &block
      else
        super
      end
    end

    def column_transitive_options
      @column_transitive_options ||= @options.slice(*COLUMN_TRANSITIVE_OPTIONS)
    end

    def each_resource
      case paginate_with
      when :find_each
        @collection.find_each{ |resource| yield resource }
      when :kaminari
        (1..kaminari_collection.total_pages).each do |page|
          kaminari_collection(page).each{ |resource| yield resource }
        end
      when Proc
        paginate_with.call(@collection).each{ |resource| yield resource }
      else
        fail "unexpected argument for paginate_with: #{paginate_with}"
      end
    end

    def kaminari_collection(page = 1)
      @collection.public_send(Kaminari.config.page_method_name, page).per 1000
    end

    class Column
      attr_reader :name, :data, :options

      DEFAULT_OPTIONS = { humanize_name: true }

      def initialize(name, resource = nil, options = {}, block = nil)
        @options = options.reverse_merge(DEFAULT_OPTIONS)
        @name = humanize_name(name, resource, @options[:humanize_name])
        @data = block || name.to_sym
      end

      def humanize_name(name, resource, humanize_name_option)
        if humanize_name_option
          name.is_a?(Symbol) && resource.present? ? resource.human_attribute_name(name) : name.to_s.humanize
        else
          name.to_s
        end
      end
    end
  end
end
