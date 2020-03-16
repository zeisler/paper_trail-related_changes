module PaperTrail
  module RelatedChanges
    class Hierarchy
      require "paper_trail/related_changes/hierarchy/query"

      class << self
        # Builds downward relational hierarchy with 4 generations
        def build(*args)
          self.new(*args).send(:build_source)
        end

        # Does filtering of relations
        def model_type_children(model)
          self.new(model).model_type_children
        end
      end

      attr_reader :model

      def initialize(model)
        @model = model
      end

      def find_by_id(id)
        Query.call(model, id)
      end

      # Find the node that matches the item_type
      # The result has a parent reference instead of a child reference.
      def search_hierarchy(item_type, source: send(:source), parent: nil)
        parent_without_children = (parent || source).except(:children)
        return [source.except(:children).merge(parent: parent_without_children)] if source[:type] == item_type
        return if source[:children].empty?
        source[:children].flat_map { |child| search_hierarchy(item_type, source: child, parent: source) }.compact
      end

      # Finds a common root between versions
      def shared_relation(versions)
        result = versions.map do |version|
          [
            version.item_type, # It can be it's self
            *search_hierarchy(version.item_type).map { |s| s.fetch(:parent, {}).fetch(:type, s[:type]) }
          ].uniq
        end.inject(:&)&.last

        search_hierarchy(result)&.first
      end

      def model_type_children
        @model_type_children ||= model.reflections.each_with_object({}) do |(name, rel), result|
          next if source_reflection(rel).belongs_to? # Only Looking for downward relations. (Children not parents)
          next if name == PaperTrail::Version.table_name
          result[name.to_sym] = source_reflection(rel)
        end
      end

      def source
        @source ||= build_source
      end

      private

      def build_source
        top_relation = SelfRelation.new(foreign_key: :id, class_name: model.name, name: model.name)
        root         = Node.new(type: model.name, name: model.name, relation: top_relation, children: [])
        model_type_children.each do |n1, r1|
          next if r1.klass == model

          r1_branch = Node.new(type: r1.klass.name, name: n1, relation: r1, children: [])
          root.children << r1_branch

          self.class.model_type_children(r1.klass).each do |n2, r2|
            next if r2.klass == model

            r2_branch = Node.new(type: r2.klass.name, name: n2, relation: r2, children: [])
            r1_branch.children << r2_branch

            self.class.model_type_children(r2.klass).each do |n3, r3|
              next if r3.klass == model

              r3_branch = Node.new(type: r3.klass.name, name: n3, relation: r3, children: [])
              r2_branch.children << r3_branch
            end
          end
        end
        root
      end

      def source_reflection(v)
        v.through_reflection? ? source_reflection(v.through_reflection) : v
      end

      def include_parent?(name)
        include_parent_as_child.include?(name.to_sym)
      end

      def whitelisted_child?(name)
        return true unless only_include_children

        only_include_children.include?(name.to_sym)
      end

      SelfRelation = Struct.new(:foreign_key, :class_name, :name, keyword_init: true)
      Node         = Struct.new(:type, :name, :relation, :children, keyword_init: true) do
        def to_simple
          base = to_h.except(:relation, :children)
          return { **base, children: children.map(&:to_simple) } unless children.empty?
          base
        end

        def except(*args)
          to_h.except(*args)
        end
      end
    end
  end
end
