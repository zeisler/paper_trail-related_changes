module PaperTrail
  module RelatedChanges
    class Engine < ::Rails::Engine
      isolate_namespace PaperTrail::RelatedChanges
    end
  end
end
