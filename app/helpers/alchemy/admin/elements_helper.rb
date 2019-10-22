# frozen_string_literal: true

module Alchemy
  module Admin
    module ElementsHelper
      include Alchemy::Admin::ContentsHelper
      include Alchemy::Admin::EssencesHelper

      # Returns an elements array for select helper.
      #
      # @param [Array] elements definitions
      # @return [Array]
      #
      def elements_for_select(elements)
        return [] if elements.nil?
        elements.collect do |e|
          [
            Element.display_name_for(e['name']),
            e['name']
          ]
        end
      end

      # CSS classes for the element editor partial.
      def element_editor_classes(element)
        [
          'element-editor',
          element.content_definitions.present? ? 'with-contents' : 'without-contents',
          element.nestable_elements.any? ? 'nestable' : 'not-nestable',
          element.taggable? ? 'taggable' : 'not-taggable',
          element.folded ? 'folded' : 'expanded',
          element.compact? ? 'compact' : nil,
          element.fixed? ? 'is-fixed' : 'not-fixed'
        ].join(' ')
      end

      # Tells us, if we should show the element footer and form inputs.
      def element_editable?(element)
        return false if element.folded?
        element.content_definitions.present? || element.taggable?
      end
    end
  end
end
