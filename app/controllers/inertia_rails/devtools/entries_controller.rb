# frozen_string_literal: true

module InertiaRails
  module Devtools
    # Read API for the DevTools extension. Deliberately not inheriting from the
    # host app's ApplicationController: the panel must keep working when the app
    # forces authentication, and the entries carry no app state of their own.
    class EntriesController < ActionController::Base
      protect_from_forgery with: :null_session

      before_action :ensure_devtools_enabled!
      before_action :authorize_devtools!

      def index
        entries = InertiaRails::Devtools.repository.all
        entries = entries.select { |entry| entry['component'] == params[:component] } if params[:component].present?

        include_types = type_list(params[:type])
        exclude_types = type_list(params[:exclude])
        entries = entries.select { |entry| include_types.include?(entry['requestType']) } if include_types.any?
        entries = entries.reject { |entry| exclude_types.include?(entry['requestType']) } if exclude_types.any?

        entries = entries.drop([params[:offset].to_i, 0].max)
        entries = entries.first([params[:limit].to_i, 1].max) if params[:limit].present?

        render json: entries
      end

      def show
        entry = InertiaRails::Devtools.repository.get(params[:id])
        return render(json: { message: 'Not found.' }, status: :not_found) unless entry

        render json: entry
      end

      private

      def type_list(value)
        value.to_s.split(',').map(&:strip).reject(&:empty?)
      end

      def ensure_devtools_enabled!
        render(json: { message: 'Not found.' }, status: :not_found) unless InertiaRails::Devtools.enabled?
      end

      # Development is always allowed: a failing gate would lock a developer out
      # of their own devtools. Anywhere else access is the app's call.
      def authorize_devtools!
        return if Rails.env.development? || Rails.env.test?

        gate = InertiaRails.configuration.devtools_authorize
        return if gate && instance_exec(&gate)

        render json: { message: 'Forbidden.' }, status: :forbidden
      end
    end
  end
end
