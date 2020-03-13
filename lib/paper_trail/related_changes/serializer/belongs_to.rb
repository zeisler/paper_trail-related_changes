class PaperTrail::RelatedChanges::Serializer
  class BelongsTo

    def self.match(attribute)
      attribute.version
        .model_class
        .reflections
        .values
        .select(&:belongs_to?)
        .reject(&:polymorphic?)
        .any? { |r| r.join_foreign_key.to_sym == attribute.to_sym }
    end

    def self.serialize(attribute, change)
      new(attribute, change).serialize
    end

    attr_reader :attribute,
                :item_type,
                :change

    def initialize(attribute, change)
      @attribute = attribute
      @item_type = attribute.version.item_type
      @change    = change
    end

    def serialize
      return if association.name.to_s.underscore.singularize == attribute.request_type.to_s.underscore.singularize
      change.merge_into_root = true unless model_class.relationally_independent?
      change.add_diff(
        attribute: attribute_name,
        old:       find_record(attribute.diff[0]),
        new:       find_record(attribute.diff[1]),
        rank:      3,
        source:    self.class.name
      )
    end

    def attribute_name
      association.name
    end

    def association
      @association ||= item_type
                         .constantize
                         .reflections
                         .detect { |_, a| a.foreign_key.to_sym == attribute.to_sym }&.fetch(1)
    end

    def find_record(id)
      return unless id
      find_associated_version(id).try(:name) || find_current_record(id).try(:name) || "Record no longer exists"
    end

    def model_class
      @model_class ||= association.klass
    end

    def find_current_record(id)
      model_class.find_by(id: id)
    end

    def find_associated_version(id)
      PaperTrail::Version.where(
        PaperTrail::Version.arel_table[:created_at].lt(attribute.version.created_at)
      ).where(
        item_id:   id,
        item_type: model_class.name
      ).order(created_at: :desc).first
    end
  end
end
