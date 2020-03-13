class PaperTrail::RelatedChanges::Serializer
  class Skippable
    def self.match(attribute)
      !!SKIP_COLUMNS.detect do |sk|
        sk == attribute.to_sym
      end
    end

    SKIP_COLUMNS = [
      :id,
      :created_at,
      :updated_at,
    ].freeze

    def self.serialize(*); end
  end
end
