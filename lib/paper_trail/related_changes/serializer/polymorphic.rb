class PaperTrail::RelatedChanges::Serializer
  module Polymorphic
    def self.match(attribute)
      attribute.version.item_type.constantize.reflections.detect { |_, r| r.polymorphic? && r.belongs_to? }
    end

    def self.serialize(attribute, change)
      return if [/_id/, /_type/].any? { |r| attribute.to_s =~ r } # Catch all non-associative attributes
      change.merge_into_root = true unless attribute.version.model_class.relationally_independent?
      change.add_diff(
        attribute: attribute.version.item_type.titleize,
        old:       attribute.diff[0],
        new:       attribute.diff[1],
        rank:      2,
        source:    self.name
      )
    end
  end
end
