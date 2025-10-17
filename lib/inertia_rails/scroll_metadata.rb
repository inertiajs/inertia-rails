# frozen_string_literal: true

module InertiaRails
  module ScrollMetadata
    class MissingMetadataAdapterError < StandardError; end

    class Props
      def initialize(page_name:, previous_page:, next_page:, current_page:)
        @page_name = page_name
        @previous_page = previous_page
        @next_page = next_page
        @current_page = current_page
      end

      def as_json(_options = nil)
        {
          pageName: @page_name,
          previousPage: @previous_page,
          nextPage: @next_page,
          currentPage: @current_page,
        }
      end
    end

    class KaminariAdapter
      def match?(metadata)
        defined?(Kaminari) && metadata.is_a?(Kaminari::PageScopeMethods)
      end

      def call(metadata, **_options)
        {
          page_name: (Kaminari.config.param_name || 'page').to_s,
          previous_page: metadata.prev_page,
          next_page: metadata.next_page,
          current_page: metadata.current_page,
        }
      end
    end

    class PagyAdapter
      def match?(metadata)
        defined?(Pagy) && metadata.is_a?(Pagy)
      end

      def call(metadata, **_options)
        {
          page_name: metadata.vars.fetch(:page_param).to_s,
          previous_page: metadata.prev,
          next_page: metadata.next,
          current_page: metadata.page,
        }
      end
    end

    class HashAdapter
      def match?(metadata)
        metadata.is_a?(Hash)
      end

      def call(metadata, **_options)
        {
          page_name: metadata.fetch(:page_name),
          previous_page: metadata.fetch(:previous_page),
          next_page: metadata.fetch(:next_page),
          current_page: metadata.fetch(:current_page),
        }
      end
    end

    class << self
      attr_accessor :adapters

      def extract(metadata, **options)
        overrides = options.slice(:page_name, :previous_page, :next_page, :current_page)

        adapters.each do |adapter|
          next unless adapter.match?(metadata)

          return Props.new(**adapter.call(metadata, **options).merge!(overrides)).as_json
        end

        begin
          Props.new(**overrides).as_json
        rescue ArgumentError
          raise MissingMetadataAdapterError, "No ScrollMetadata adapter found for #{metadata}"
        end
      end

      def register_adapter(adapter)
        adapters.unshift(adapter.new)
      end
    end

    self.adapters = [KaminariAdapter, PagyAdapter, HashAdapter].map(&:new)
  end
end
