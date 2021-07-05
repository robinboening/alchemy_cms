# frozen_string_literal: true

require "alchemy/upgrader"

module Alchemy::Upgrader::Tasks
  class IngredientsMigrator < Thor
    include Thor::Actions

    no_tasks do
      def create_ingredients
        Alchemy::Deprecation.silence do
          elements_with_ingredients = Alchemy::ElementDefinition.all.select { |d| d.key?(:ingredients) }
          # eager load all elements that have ingredients defined but no ingredient records yet.
          all_elements = Alchemy::Element
            .named(elements_with_ingredients.map { |d| d[:name] })
            .includes(contents: { essence: :ingredient_association })
            .left_outer_joins(:ingredients).where(alchemy_ingredients: { id: nil })
            .to_a
          elements_with_ingredients.map do |element_definition|
            elements = all_elements.select { |e| e.name == element_definition[:name] }
            if elements.any?
              puts "-- Creating ingredients for #{elements.count} #{element_definition[:name]}(s)"
              elements.each do |element|
                Alchemy::Element.transaction do
                  element_definition[:ingredients].each do |ingredient_definition|
                    content = element.content_by_name(ingredient_definition[:role])
                    next unless content

                    essence = content.essence
                    ingredient = Alchemy::Ingredient.build(role: ingredient_definition[:role], element: element)
                    belongs_to_associations = essence.class.reflect_on_all_associations(:belongs_to)
                    if belongs_to_associations.any?
                      ingredient.related_object = essence.public_send(belongs_to_associations.first.name)
                    else
                      ingredient.value = content.ingredient
                    end
                    ingredient.class.stored_attributes.fetch(:data, []).each do |attr|
                      value = essence.public_send(attr)
                      ingredient.public_send("#{attr}=", value)
                    end
                    print "."
                    ingredient.save!
                    content.destroy!
                  end
                end
              end
              puts "\n"
            else
              puts "-- No #{element_definition[:name]} elements found for migration."
            end
          end
        end
      end
    end
  end
end
