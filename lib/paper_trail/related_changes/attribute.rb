module PaperTrail::RelatedChanges
  Attribute = Struct.new(:name, :diff, :version, :request_type, keyword_init: true) do
    def to_s
      name.to_s
    end

    def to_sym
      name.to_sym
    end
  end
end
