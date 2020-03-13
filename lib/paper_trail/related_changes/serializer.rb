require "paper_trail/related_changes/serializer/polymorphic"
require "paper_trail/related_changes/serializer/belongs_to"
require "paper_trail/related_changes/serializer/skippable"
require "paper_trail/related_changes/attribute"
require "paper_trail/related_changes/serializer/diff"
require "paper_trail/related_changes/change"

module PaperTrail
  module RelatedChanges
    class Serializer
      def initialize(record, item_type:, model_to_include_name: {}, root_type: nil)
        @record                = record
        @item_type             = item_type
        @model_to_include_name = model_to_include_name
        @root_type             = root_type
      end

      delegate :to_h, to: :change

      def change
        @change ||= change_template
        build_changes
        @change
      end

      private

      def change_template
        Change.new(
          version_id:     record.id,
          user:           user,
          event:          record.event,
          resource:       record.item_type,
          description:    {
            name:  resource_title,
            value: record.name
          },
          resource_id:    record.item_id,
          timestamp:      record.created_at,
          requested_root: !included?
        )
      end

      attr_reader :record,
                  :item_type,
                  :model_to_include_name,
                  :root_type

      def included?
        return record.item_type != root_type unless root_type.nil?
        record.item_type != item_type.classify
      end

      def resource_title
        model_to_include_name.fetch(
          record.item_type,
          record.item_type.underscore.split('/').last
        ).to_s.singularize.titleize
      end

      def user
        PaperTrail::RelatedChanges.user_class.find_by(id: record.whodunnit)&.name || "system"
      end

      def build_changes
        @build_changes ||= record.changeset.each do |attr, diff|
          BuildDiffs.new(attr, diff, record, item_type, @change).call
        end
      end

      class BuildDiffs
        def initialize(attr, diff, record, request_type, change)
          @attr         = attr.to_sym
          @diff         = diff
          @record       = record
          @request_type = request_type
          @change       = change
        end

        def call
          return call_serializer if custom_serializer

          change.diffs << default_diff
        end

        private

        attr_reader :diff,
                    :attr,
                    :record,
                    :request_type,
                    :change

        def default_diff
          Diff.new(attribute: attr, old: diff[0], new: diff[1], rank: 0, meta: record, source: :default)
        end

        def attribute
          @attribute ||= Attribute.new(
            name:         attr,
            diff:         diff,
            version:      record,
            request_type: request_type
          )
        end

        def custom_serializer
          RelatedChanges.serializers.detect { |serializer| serializer.match(attribute) }
        end

        def call_serializer
          custom_serializer.serialize(attribute, change)
        end
      end
    end
  end
end
