module PaperTrail
  module RelatedChanges
    class Engine < ::Rails::Engine
      isolate_namespace PaperTrail::RelatedChanges

      ActiveSupport.on_load(:active_record) do
        extend PaperTrail::RelatedChanges::RelationallyIndependent
      end

      config.after_initialize do
        PaperTrail::Version.include(PaperTrail::VersionModel)
      end
    end
  end
end
