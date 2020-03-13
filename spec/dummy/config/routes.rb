Rails.application.routes.draw do
  mount PaperTrail::RelatedChanges::Engine => "/related_changes"
end
