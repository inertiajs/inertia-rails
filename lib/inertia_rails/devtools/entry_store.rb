# frozen_string_literal: true

require 'fileutils'
require 'securerandom'
require 'active_support/core_ext/file/atomic'

module InertiaRails
  module Devtools
    # One JSON file per entry, a directory per tab. Ids start with a timestamp, so file names sort by time.
    class EntryStore
      ID_FORMAT = /\A\d{19}-\h{16}\z/
      NO_TAB = '_'
      TAB_PATTERN = /\A[\w-]{1,64}\z/
      SUPPRESS_SECONDS = 30

      # Nanosecond time plus random hex: ids sort by time and don't clash across processes.
      def self.generate_id
        "#{Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)}-#{SecureRandom.hex(8)}"
      end

      def read(id)
        return unless ID_FORMAT.match?(id)

        file = Dir.glob(File.join(path, '*', "#{id}.json")).first
        read_json(file) if file
      end

      def list(component: nil, types: [], exclude: [], offset: nil, limit: nil)
        metas = entry_files.sort_by { |file| File.basename(file) }.reverse.filter_map do |file|
          meta = read_json(file)&.dig('__meta')
          meta if meta && listed?(meta, component, types, exclude)
        end
        metas = metas.drop(offset) if offset&.positive?
        limit ? metas.first([limit, 1].max) : metas
      end

      def write(id, entry, tab_uuid: nil)
        raise ArgumentError, 'Invalid Inertia DevTools entry id.' unless ID_FORMAT.match?(id)
        return if suppressed?

        write_file(id, entry, File.join(path, TAB_PATTERN.match?(tab_uuid.to_s) ? tab_uuid : NO_TAB))
        @suppressed_until = nil
      rescue SystemCallError, IOError => e
        suppress(e)
      end

      private

      def path
        File.expand_path(config.storage_path, Rails.root)
      end

      def write_file(id, entry, dir)
        new_tab = !File.directory?(dir)
        FileUtils.mkdir_p(dir, mode: 0o700)
        File.atomic_write(File.join(dir, "#{id}.json")) { |file| file.write(JSON.generate(entry)) }

        evict(dir)
        # A closed tab never writes again, so old entries are cleaned up when a new tab starts.
        expire if new_tab
      end

      def evict(dir)
        limit = config.limit
        return unless limit.positive?

        files = Dir.glob(File.join(dir, '*.json'))
        FileUtils.rm_f(files.first(files.length - limit)) if files.length > limit
      end

      # Other processes may be deleting the same files.
      def expire
        cutoff = config.ttl.hours.ago

        entry_files.each do |file|
          FileUtils.rm_f(file) if File.mtime(file) < cutoff
        rescue SystemCallError
          next
        end
        Dir.glob(File.join(path, '*/')).each do |dir|
          Dir.rmdir(dir) if Dir.empty?(dir) && File.mtime(dir) < cutoff
        rescue SystemCallError
          next
        end
      end

      def listed?(meta, component, types, exclude)
        (component.nil? || meta['component'] == component) &&
          (types.empty? || types.include?(meta['requestType'])) &&
          exclude.exclude?(meta['requestType'])
      end

      def entry_files
        Dir.glob(File.join(path, '*', '*.json'))
      end

      def read_json(file)
        parsed = JSON.parse(File.read(file))
        parsed if parsed.is_a?(Hash)
      rescue SystemCallError, JSON::ParserError
        nil
      end

      def suppressed?
        @suppressed_until && monotonic < @suppressed_until
      end

      def suppress(error)
        Devtools.report(error) if @suppressed_until.nil?
        @suppressed_until = monotonic + SUPPRESS_SECONDS
      end

      def monotonic
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def config
        Devtools.config
      end
    end
  end
end
