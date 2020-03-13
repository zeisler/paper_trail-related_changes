require "paper_trail/related_changes/engine"
require 'paper_trail/frameworks/active_record/models/paper_trail/version'
require 'paper_trail/related_changes/model'
require 'paper_trail/related_changes/active_record/base'
require "paper_trail/related_changes/serializer"
require "paper_trail/related_changes/grouped_by_request_id"
require "paper_trail/related_changes/hierarchy"
require "paper_trail/related_changes/build_changes"
require "paper_trail/related_changes/version"

module PaperTrail
  module RelatedChanges
    def self.serializers
      @serializers ||= [
        Serializer::Skippable,
        Serializer::BelongsTo,
        Serializer::Polymorphic
      ]
    end

    def self.insert_after_serializer(serializer, after_serializer)
      serializer_index = serializers.index(serializer)
      @serializers = serializers.insert(serializer_index + 1, after_serializer)
    end

    def self.insert_before_serializer(serializer, after_serializer)
      serializer_index = serializers.index(serializer)
      @serializers = serializers.insert(serializer_index, after_serializer)
    end

    def self.user_class
      User if defined? User
    end
  end
end
