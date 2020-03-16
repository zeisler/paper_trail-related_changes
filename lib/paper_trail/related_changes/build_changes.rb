module PaperTrail
  module RelatedChanges
    class BuildChanges
      attr_reader :results,
                  :model_type_children,
                  :item_type,
                  :item_id

      def initialize(results, model_type_children, item_type, item_id)
        @results             = results
        @model_type_children = model_type_children
        @item_type           = item_type
        @item_id             = item_id
      end

      def call
        changes = results.map do |root_version, versions, request_id|
          versions_serialized         = versions_serialized(versions)
          root_change                 = change_with_root(request_id, root_version, versions_serialized)
          root_change.change.children = children_versions(versions_serialized).map(&:change)
          root_change.change
        end.compact

        remove_duplicate_changes(changes)
      end

      private

      # Given a case where a change is represented by a previous change do not show it.
      def remove_duplicate_changes(changes)
        changes.reject.with_index do |change, index|
          stop_iteration = false
          changes[(index + 1)..-1].each do |previous_change|
            change.diffs = change.diffs.reject do |current_change|
              next false if stop_iteration
              previous_matched_change = previous_change
                                          .diffs
                                          .detect { |previous_change| previous_change.attribute == current_change.attribute }
              stop_iteration          = true if previous_matched_change # As soon as their is match stop
              previous_matched_change.eql?(current_change)
            end
          end

          change.empty?
        end
      end

      def change_with_root(request_id, root_version, versions_serialized)
        s                   = Serializer.new(root_version, item_type: root_version.item_type, root_type: item_type)
        s.change.diffs      = [*s.change.diffs, *attribute_version_changes(versions_serialized)]
        s.change.version_id = request_id || root_version.request_id
        s
      end

      def children_versions(versions_serialized)
        versions_serialized.reject { |vr| vr.change.merge_into_root }
      end

      def attribute_version_changes(versions_serialized)
        versions_serialized.select { |vr| vr.change.merge_into_root }.map(&:change).flat_map(&:diffs)
      end

      def versions_serialized(versions)
        versions.flat_map do |parent_type, versions_with_child_type|
          versions_with_child_type.flat_map do |_type, versions_of_child|
            versions_of_child.map do |version|
              Serializer.new(
                version,
                item_type:             parent_type,
                model_to_include_name: model_to_include_name,
                root_type:             item_type
              )
            end
          end
        end
      end

      def model_to_include_name
        model_type_children.each_with_object({}) { |(n, r), h| h[r.klass.name] = n }
      end
    end
  end
end
