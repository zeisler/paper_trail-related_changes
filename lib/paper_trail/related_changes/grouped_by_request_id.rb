module PaperTrail
  module RelatedChanges
    # Goal of class is to group versions rows into groups that represent a user event.
    # When a user saves a resource that may have many associated resources and we want to see that as one event.
    # Use ActiveRecord#reflections build a tree of downward relationships and query the versions.object and version.object_changes
    # Group by the request_id to collect all actions into an event.
    class GroupedByRequestId
      attr_reader :item_id,
                  :item_type,
                  :limit

      def initialize(item_type: nil, type: nil, item_id: nil, id: nil, limit: nil)
        @item_type   = (item_type || type).underscore.classify
        @item_id     = item_id || id
        @limit       = Integer([limit, 1_000].reject(&:blank?).first)
        @append_root = true
      end

      def to_a
        BuildChanges.new(
          raw_records,
          hierarchy.model_type_children,
          model_name,
          item_id
        ).call.take(limit) # appending the last root version can cause limit+1 sized results.
      end

      def raw_records
        results.map do |result|
          root_version, versions = build_versions(result)
          [root_version, group_versions(versions), result["request_id"]]
        end.concat(append_root_version)
      end

      private

      # When a limit is used you may not have a root record. A root record will collapse many versions into it's self.
      # Without a root record you will see different types of records that won't be seen when no limit is set.
      def append_root_version
        return [] unless @append_root
        [[last_root, []]]
      end

      def results
        conn = ActiveRecord::Base.connection
        conn.execute(<<~SQL)
          SELECT json_agg(hierarchy_versions ORDER BY (rank, item_type, item_id, id)) AS versions,
                 MIN(hierarchy_versions.created_at) as created_at,
                 request_id
             FROM (#{RelatedChanges::Hierarchy::Query.call(model_class, item_id)}) AS hierarchy_versions
             GROUP BY request_id
             ORDER BY created_at DESC
             LIMIT #{conn.quote(limit)}
        SQL
      end

      def last_root
        @last_root ||= PaperTrail::Version.where(
          item_type: item_type,
          item_id:   item_id
        ).order(
          created_at: :desc
        ).limit(1).first
      end

      def build_versions(result)
        requested_root_version = nil
        versions               = JSON.parse(result["versions"]).map do |version|
          record                 = convert_to_record(version)
          requested_root_version = record if record.item_id == item_id && record.item_type == model_name
          record
        end
        @append_root           = false if requested_root_version == last_root
        root_version           = requested_root_version || find_root(versions, result["request_id"])
        versions.delete(root_version)
        [root_version, versions]
      end

      def find_root(versions, request_id)
        return versions.first if versions.count == 1 && versions.first.model_class.relationally_independent?
        shared_relation = hierarchy.shared_relation(versions)
        root_version    = versions.detect { |version| version.item_type == shared_relation.dig(:relation).class_name }

        return build_sudo_root(shared_relation, request_id, versions) unless root_version
        root_version
      end

      def merge_event(versions)
        if versions.map(&:event).uniq.count == 1
          versions.map(&:event).uniq.first
        else
          'update'
        end
      end

      def convert_to_record(version)
        PaperTrail::Version.new(
          **version.except('created_at', 'rank').symbolize_keys,
          created_at: ActiveSupport::TimeZone["UTC"].parse(version['created_at'])
        )
      end

      def group_versions(versions)
        versions.each_with_object({}) do |version, hash|
          sources = hierarchy.search_hierarchy(version.item_type)

          next unless (relation_to_root = sources.min_by { |s| s[:name].length }) # Prefer the shortest name ie. note vs notes
          hash[relation_to_root[:parent][:type]]                          ||= {}
          hash[relation_to_root[:parent][:type]][relation_to_root[:name]] ||= []
          hash[relation_to_root[:parent][:type]][relation_to_root[:name]] << version
        end
      end

      def build_sudo_root(shared_relation, request_id, versions)
        # Assigning the parent_id will allow the description.name to be populated.
        extracted_reference_keys = versions.map { |version| hierarchy.search_hierarchy(version.item_type)&.first&.fetch(:relation) }.map { |v| [v.foreign_key, v.type].compact }
        parent_id                = versions.flat_map { |version| extracted_reference_keys.map { |keys| version.extract(*keys) } }.flatten.select { |t| t.class == Integer }.first

        PaperTrail::Version.new(
          item_type:  shared_relation.dig(:relation).class_name,
          item_id:    parent_id,
          request_id: request_id,
          event:      merge_event(versions),
          created_at: versions.first.created_at,
          whodunnit:  versions.first.whodunnit
        )
      end

      # This might happen if a developer did a mass edit in the console of unrelated items.
      # If there are competing versions that match the request type only include the one with the matching id
      def remove_stowaways(requested_root_version, versions)
        versions.reject do |version|
          version.item_type == requested_root_version.item_type && version.item_id != requested_root_version.item_id
        end
      end

      def model_class
        model_name.constantize
      end

      def model_name
        item_type.underscore.classify
      end

      def hierarchy
        @hierarchy ||= PaperTrail::RelatedChanges::Hierarchy.new(model_class)
      end
    end
  end
end
