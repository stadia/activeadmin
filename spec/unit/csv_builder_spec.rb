# Encoding: UTF-8

require 'rails_helper'

describe ActiveAdmin::CSVBuilder do
  let(:builder) { ActiveAdmin::CSVBuilder.new options, &block }
  let(:options) { {} }
  let(:block)   { ->{} }

  let(:view_context) {
    context = Class.new
    context.send :include, MethodOrProcHelper
    context.new
  }
  let(:controller) {
    controller = double view_context: view_context, find_collection: collection
    allow(controller).to receive(:apply_decorator) { |r| r }
    controller
  }
  let(:collection) { Post.all }

  before{ |ex| builder.send :exec_columns, view_context unless ex.metadata[:skip_exec] }

  before :all do
    Post.destroy_all
    @post1 = Post.create!(title: "Hello1", published_at: Date.today - 2.day )
    @post2 = Post.create!(title: "Hello2", published_at: Date.today - 1.day )
  end

  context 'when empty' do
    it "has no columns" do
      expect(builder.columns).to eq []
    end
  end

  context "with a symbol column (:title)" do
    let(:block) {
      ->{ column :title }
    }

    it "has one column" do
      expect(builder.columns.size).to eq 1
    end

    describe "the column" do
      let(:column){ builder.columns.first }

      it "has a name of 'Title'" do
        expect(column.name).to eq "Title"
      end

      it "has the data :title" do
        expect(column.data).to eq :title
      end
    end
  end

  context "with a block and title" do
    let(:block) {
      -> {
        column 'My title' do
          # nothing
        end
      }
    }

    it "has one column" do
      expect(builder.columns.size).to eq 1
    end

    describe "the column" do
      let(:column){ builder.columns.first }

      it "has a name of 'My title'" do
        expect(column.name).to eq "My title"
      end

      it "has the data :title" do
        expect(column.data).to be_an_instance_of(Proc)
      end
    end
  end

  describe ":humanize_name" do
    context "set on column with symbol column name" do
      let(:block) {
        -> {
          column :my_title, humanize_name: false
        }
      }

      describe "the column" do
        let(:column){ builder.columns.first }

        it "has a name of 'my_title'" do
          expect(column.name).to eq "my_title"
        end
      end
    end

    context "set on column with string column name" do
      let(:block) {
        -> {
          column "my_title", humanize_name: false
        }
      }

      describe "the column" do
        let(:column){ builder.columns.first }

        it "has a name of 'my_title'" do
          expect(column.name).to eq "my_title"
        end
      end
    end

    context "set on builder" do
      let(:options) { {humanize_name: false} }
      let(:block)   { ->{ column :my_title } }

      describe "the column" do
        let(:column){ builder.columns.first }

        it "has humanize_name option set" do
          expect(column.options).to eq humanize_name: false
        end

        it "has a name of 'my_title'" do
          expect(column.name).to eq "my_title"
        end
      end
    end
  end

  describe ":col_sep" do
    let(:options) { {col_sep: ';'} }

    it "uses the proper separator" do
      expect(builder.options).to eq col_sep: ';'
    end
  end

  describe "CSV options" do
    let(:options) { {force_quotes: true} }

    it "are kept around" do
      expect(builder.options).to eq col_sep: ',', force_quotes: true
    end
  end

  describe '.default_for_resource using Post' do
    let(:builder) { ActiveAdmin::CSVBuilder.default_for_resource Post }

    it 'defines Id as the first column' do
      expect(builder.columns.first.name).to eq 'Id'
      expect(builder.columns.first.data).to eq :id
    end

    it "has Post's content_columns" do
      builder.columns[1..-1].each_with_index do |column, index|
        expect(column.name).to eq Post.content_columns[index].name.humanize
        expect(column.data).to eq Post.content_columns[index].name.to_sym
      end
    end

    context 'when column has a localized name', skip_exec: true do
      before do
        allow(Post).to receive(:human_attribute_name).and_call_original
        allow(Post).to receive(:human_attribute_name).with(:title){ 'Titulo' }
        builder.send :exec_columns
      end

      it 'gets name from I18n' do
        title_index = Post.content_columns.map(&:name).index('title')
        expect(builder.columns[title_index + 1].name).to eq 'Titulo'
      end
    end
  end

  context "with access to the controller"do
    let(:view_context) { double controller: double(names: %w(title summary updated_at created_at)) }
    let(:block) {
      -> {
        column "id"
        controller.names.each{ |name| column name }
      }
    }

    it "builds columns provided by the controller" do
      expect(builder.columns.map(&:data)).to match_array([:id, :title, :summary, :updated_at, :created_at])
    end
  end

  it "generates data ignoring pagination" do
    expect(controller).to receive(:find_collection).with(except: :pagination).once
    expect(builder).to    receive(:build_row).and_return([]).twice
    builder.build controller, []
  end

  describe "paginate_with: :per_page" do
    it "works" do
      expect(collection).to receive(:find_each).and_call_original
      builder.build controller, []
    end
  end

  describe "paginate_with: <Proc>" do
    let(:options) { {paginate_with: ->collection { collection }} }

    it "works" do
      expect(collection).to receive(:each).and_call_original
      builder.build controller, []
    end
  end

  describe "paginate_with: :kaminari" do
    let(:options) { {paginate_with: :kaminari} }
    let(:collection) { Post.order published_at: :desc }
    let(:block) {
      -> {
        column "id"
        column "title"
        column "published_at"
      }
    }

    it "generates data with the supplied order" do
      expect(builder).to receive(:build_row).and_return([]).once.ordered { |post| expect(post.id).to eq @post2.id }
      expect(builder).to receive(:build_row).and_return([]).once.ordered { |post| expect(post.id).to eq @post1.id }
      builder.build controller, []
    end
  end

  describe ":encoding and :encoding_options" do
    let(:encoding) { Encoding::ASCII }
    let(:encoding_options) { {} }
    let(:options) { {encoding: encoding, encoding_options: encoding_options} }
    let(:block) {
      -> {
        column("おはようございます") { |p| p.title }
      }
    }

    context "Shift-JIS" do
      let(:encoding) { Encoding::Shift_JIS }
      let(:encoding_options) { {invalid: :replace, undef: :replace, replace: "?"} }

      it "encodes the CSV" do
        csv = []
        builder.build controller, csv

        expect(csv.map(&:encoding).uniq).to eq [encoding]
        expect(csv).to include "おはようございます\n".encode(encoding, encoding_options)
      end
    end

    context "ASCII" do
      let(:encoding) { Encoding::ASCII }
      let(:encoding_options) { {invalid: :replace, undef: :replace, replace: "__REPLACED__"} }

      it "encodes the CSV without errors" do
        csv = []
        builder.build controller, csv

        expect(csv.map(&:encoding).uniq).to eq [encoding]
        expect(csv.first).to include "__REPLACED__"
      end
    end
  end

  skip '#build'

  skip '#exec_columns'

  skip '#build_row' do
    it 'renders non-strings'
    it 'encodes values correctly'
    it 'passes custom encoding options to String#encode!'
  end

end
