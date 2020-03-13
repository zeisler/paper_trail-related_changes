module PaperTrail::RelatedChanges::Hierarchy::Query
  class << self
    # Builds a UNION joined set of queries that finds related versions to the 4th generation.
    def call(model, id)
      parent_query_r0 = parent(model.name, id)
      hierarchy       = PaperTrail::RelatedChanges::Hierarchy.model_type_children(model).each_with_object([]) do |(_n, r1), col|
        parent_query_r1 = call_query(parent_query_r0, r1)
        col << parent_query_r1
        PaperTrail::RelatedChanges::Hierarchy.model_type_children(r1.klass).each do |_n, r2|
          parent_query_r2 = call_query(parent_query_r1, r2)
          col << parent_query_r2
          PaperTrail::RelatedChanges::Hierarchy.model_type_children(r2.klass).each do |_n, r3|
            parent_query_r3 = call_query(parent_query_r2, r3)
            col << parent_query_r3
          end
        end
      end
      final           = [
        parent_query_r0,
        *hierarchy.uniq
      ].join("\nUNION\n")

      <<~SQL
        SELECT #{columns('hierarchy')},
          CASE event
          WHEN 'create' THEN 1
          WHEN 'update' THEN 2
          WHEN 'destroy' THEN 3
          ELSE 4 END as rank
        FROM (#{final}) hierarchy
      SQL
    end

    private

    def call_query(parent_query, r)
      if r.type
        nth_polymorphic_children(parent_query, r.type, r.foreign_key)
      else
        nth_children(parent_query, r.foreign_key)
      end
    end

    def parent(item_type, item_id)
      <<~SQL
        SELECT '#{item_type}=>#{item_id}' as tree, #{columns('versions')}
        FROM versions
        WHERE versions.item_type = '#{item_type}'
          AND versions.item_id = '#{item_id}'
      SQL
    end

    def nth_children(parent_query, parent_foreign_key)
      <<~SQL
        SELECT parents.tree || '.' || children.item_type || '=>' || children.item_id as tree, #{columns('children')}
        FROM (#{parent_query}) parents
        JOIN versions children ON parents.item_id = #{query_changes(parent_foreign_key)}
      SQL
    end

    def nth_polymorphic_children(parent_query, parent_type_foreign_key, parent_id_foreign_key)
      <<~SQL
        SELECT parents.tree || '.' ||  children.item_type || '=>' || children.item_id as tree, #{columns('children')}
        FROM (#{parent_query}) parents
          JOIN versions children ON  parents.item_id = #{query_changes(parent_id_foreign_key)}
        AND parents.item_type = #{query_changes(parent_type_foreign_key)}
      SQL
    end

    def query_changes(key)
      "COALESCE((children.object_changes -> '#{key}' ->> 1)::TEXT, (children.object ->> '#{key}')::TEXT)"
    end

    def columns(prefix)
      %w(id item_type item_id event whodunnit object object_changes request_id created_at).map { |c| "#{prefix}.#{c}" }.join(", ")
    end
  end
end
