module PaperTrail::RelatedChanges
  Change = Struct.new(:version_id,
                      :user,
                      :event,
                      :resource,
                      :description,
                      :resource_id,
                      :diffs,
                      :timestamp,
                      :requested_root,
                      :children,
                      :merge_into_root,
                      keyword_init: true) do
    def initialize(diffs: [], merge_into_root: false, **args)
      super
    end

    def to_h(*)
      self.diffs = diffs
                     .group_by(&:source)
                     .map { |k, g| [k, g.sort_by(&:source_rank)] } # ie. segments can be in display order
                     .sort_by { |_, g| g[0].rank } # Direct attributes shown first
                     .flat_map(&:last)
                     .uniq
      results    = super().except(:merge_into_root).map { |k, v| [k, v.is_a?(Array) ? v.map(&:to_h) : v] }.to_h
      results.delete(:children) if results[:children].nil?
      results
    end

    alias_method :as_json, :to_h

    def empty?
      diffs.count.zero? && children.count.zero?
    end

    def add_diff(args)
      self.diffs << PaperTrail::RelatedChanges::Serializer::Diff.new(args)
    end
  end
end
