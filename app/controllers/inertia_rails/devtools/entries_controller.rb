# frozen_string_literal: true

module InertiaRails
  module Devtools
    class EntriesController < Devtools.config.base_controller.constantize
      prepend_before_action :skip_session_write
      before_action :authorize_devtools_access

      def index
        entries = Devtools.store.list(
          component: params[:component].presence,
          types: list_param(:type),
          exclude: list_param(:exclude),
          offset: Integer(params[:offset], 10, exception: false),
          limit: Integer(params[:limit], 10, exception: false)
        )

        render json: entries
      end

      def show
        entry = Devtools.store.read(params[:id])
        return head :not_found if entry.blank?

        render json: entry
      end

      private

      def skip_session_write
        request.session_options[:skip] = true if request.session_options
      end

      def authorize_devtools_access
        head :forbidden unless Devtools.config.allows?(self)
      end

      def list_param(name)
        params[name].to_s.split(',').map(&:strip).reject(&:empty?)
      end
    end
  end
end
