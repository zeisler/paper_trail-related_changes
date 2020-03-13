module PaperTrail
  module RelatedChanges
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
