# frozen_string_literal: true

module InertiaRails
  module Devtools
    class EntriesController < ActionController::Base
      protect_from_forgery with: :null_session

      before_action :ensure_devtools_enabled!
      before_action :authorize_devtools!

      def index
        entries = InertiaRails::Devtools.repository.all
        entries = entries.select { |entry| entry['component'] == params[:component] } if params[:component].present?

        include_types = InertiaRails::Devtools.comma_list(params[:type])
        exclude_types = InertiaRails::Devtools.comma_list(params[:exclude])

        entries = entries.select { |entry| include_types.include?(entry['requestType']) } if include_types.any?
        entries = entries.reject { |entry| exclude_types.include?(entry['requestType']) } if exclude_types.any?
        offset = integer_param(params[:offset])
        entries = entries.drop(offset.clamp(0, entries.length)) if offset

        limit = integer_param(params[:limit])
        entries = entries.first(entries.empty? ? 0 : limit.clamp(1, entries.length)) if limit

        render json: entries
      end

      def show
        entry = InertiaRails::Devtools.repository.get(params[:id])
        return render(json: { message: 'Not found.' }, status: :not_found) unless entry

        render json: entry
      end

      private

      def integer_param(value)
        Integer(value, exception: false) if value.is_a?(String) || value.is_a?(Integer)
      end

      def ensure_devtools_enabled!
        render(json: { message: 'Not found.' }, status: :not_found) unless InertiaRails::Devtools.enabled?
      end

      def authorize_devtools!
        return if Rails.env.development?

        gate = InertiaRails.configuration.devtools_authorize
        return if gate && instance_exec(&gate)

        render json: { message: 'Forbidden.' }, status: :forbidden
      end
    end
  end
end
