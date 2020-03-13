module PaperTrail
  class Version < ::ActiveRecord::Base
    include PaperTrail::VersionConcern
    DISPLAY_NAME_METHODS = [
      :title,
      :name,
      :code
    ].freeze

    def name
      call_by_name(self.next&.reify || live_record)
    rescue StandardError
      call_by_name(live_record)
    end

    def model_class
      item_type.constantize
    end

    def extract(*keys)
      result = keys.map do |key|
        (object_changes || {})[key.to_s]&.last || (object || {})[key.to_s]
      end
      return result if keys.count > 1
      result.first
    end

    private

    def live_record
      model_class.find_by(id: item_id)
    end

    def call_by_name(record)
      DISPLAY_NAME_METHODS.map { |meth| record.try(meth) }.compact.first
    end
  end
end
