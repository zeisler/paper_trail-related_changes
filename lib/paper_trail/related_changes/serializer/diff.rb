class PaperTrail::RelatedChanges::Serializer
  Diff = Struct.new(:attribute, :old, :new, :rank, :source_rank, :source, :meta, keyword_init: true) do
    def initialize(rank: 1, source_rank: 1, **args)
      super
    end

    def to_h
      if ENV['RELATED_CHANGES_DEBUG']
        super
      else
        super.except(:rank, :source, :source_rank, :meta)
      end
    end

    def eql?(other)
      attribute == other.attribute && new == other.new && old == other.old
    end

    def hash
      [attribute, new, old].hash
    end
  end
end
