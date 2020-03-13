module PaperTrail
  module RelatedChanges
    class BaseController < PaperTrail::RelatedChanges::ApplicationController
      def show
        render json: { data: versions.to_a, meta: {} }
      end

      private

      def versions
        RelatedChanges::GroupedByRequestId.new(
          limit: limit,
          **params.permit!.to_h.symbolize_keys.slice(
            :type,
            :id
          )
        )
      end

      def limit
        params.dig('page', 'size')
      end
    end
  end
end
