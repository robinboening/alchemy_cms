# frozen_string_literal: true

require "rails_helper"
require "timecop"

RSpec.describe Alchemy::Page::Publisher do
  describe "#publish!" do
    let(:current_time) { Time.current.change(usec: 0) }
    let(:page) do
      create(:alchemy_page,
             public_on: public_on,
             public_until: public_until,
             published_at: published_at)
    end
    let(:published_at) { nil }
    let(:public_on) { nil }
    let(:public_until) { nil }
    let(:publisher) { described_class.new(page) }

    subject(:publish) { publisher.publish!(public_on: current_time) }

    around do |example|
      Timecop.freeze(current_time) do
        example.run
      end
    end

    shared_context "with elements" do
      let(:page) do
        create(:alchemy_page, page_layout: "with_boolean_element", autogenerate_elements: true)
      end
    end

    context "with elements" do
      include_context "with elements"

      context "with boolean ingredient" do
        it "keeps the same ingredient value" do
          publish

          # Old value is nil (even though default is set to true)
          old_boolean_ingredient = page.draft_version.elements.find_by(name: "boolean").ingredient_by_type("Boolean")
          puts "old raw value: #{old_boolean_ingredient.read_attribute(:value).inspect}"
          puts "old casted value: #{old_boolean_ingredient.read_attribute(:value).inspect}"

          # new value is t (first character taken from the default)
          # 't' is casted to true in Ingredients::Boolean#value method
          new_boolean_ingredient = page.reload.public_version.elements.find_by(name: "boolean").ingredient_by_type("Boolean")
          puts "new raw value: #{new_boolean_ingredient.read_attribute(:value)}"
          puts "new casted value: #{new_boolean_ingredient.value}"

          expect(new_boolean_ingredient.value).to eq(old_boolean_ingredient.value)
        end
      end
    end
  end
end
