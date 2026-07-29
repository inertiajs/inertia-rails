# frozen_string_literal: true

require 'fileutils'
require 'active_support/core_ext/file/atomic'

module InertiaRails
  module Devtools
    class EntriesRepository
      INDEX_FILE = '_meta.json'
      LOCK_FILE = '_meta.lock'
      LAST_PRUNE_FILE = '_last_prune'
      SUPPRESS_SECONDS = 30

      def initialize(path:, ttl_hours: 24, prune_interval: 300)
        @path = path
        @ttl_hours = ttl_hours
        @prune_interval = prune_interval
        @suppressed_until = nil
      end

      def get(id)
        return unless Ulid.valid?(id)

        read_json(entry_path(id))
      end

      def all
        newest_first(read_index.values)
      end

      def record(id, data, tab_uuid: nil, limit: 100, max_entries: 0)
        raise ArgumentError, 'Invalid Inertia DevTools entry id.' unless Ulid.valid?(id)
        return if suppressed?

        begin
          ensure_directory
          write_atomically(entry_path(id), JSON.generate(data))

          evicted = []
          mutate_index do |index|
            index = index.merge(id => index_meta(data['__meta'] || data[:__meta] || {}))
            evicted = evicted_ids(index, tab_uuid: tab_uuid, limit: limit, max_entries: max_entries)
            index.except(*evicted)
          end
          remove_entry_files(evicted)

          @suppressed_until = nil
        rescue StandardError => e
          suppress(e)
        end
      end

      def prune
        cutoff = Time.now.to_f - (@ttl_hours * 3600)
        expired = []

        mutate_index do |index|
          expired = index.values.select { |meta| meta['utime'].to_f < cutoff }.map { |meta| meta['id'] }
          index.except(*expired)
        end

        remove_entry_files(expired)
      end

      def prune_if_due
        return if suppressed?
        return prune if @prune_interval <= 0

        ensure_directory
        last = read_last_pruned_at
        return if last && (Time.now.to_i - last) < @prune_interval

        prune
        write_atomically(File.join(@path, LAST_PRUNE_FILE), Time.now.to_i.to_s)
      rescue StandardError => e
        suppress(e)
      end

      private

      def suppressed?
        @suppressed_until && monotonic < @suppressed_until
      end

      # Storage is broken often enough to be worth backing off: report the first
      # failure and stop touching the filesystem until the window elapses.
      def suppress(error)
        Devtools.report(error) if @suppressed_until.nil?
        @suppressed_until = monotonic + SUPPRESS_SECONDS
      end

      def monotonic
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def entry_path(id)
        File.join(@path, "#{id}.json")
      end

      def index_path
        File.join(@path, INDEX_FILE)
      end

      def index_meta(meta)
        meta = meta.transform_keys(&:to_s)
        tab = meta['tabUuid']

        meta.merge(
          'id' => meta['id'].to_s,
          'tabUuid' => tab.is_a?(String) && !tab.empty? ? tab : nil,
          'utime' => meta['utime'] ? meta['utime'].to_f : Time.now.to_f
        )
      end

      def newest_first(metas)
        metas.sort_by { |meta| meta['id'].to_s }.reverse
      end

      def evicted_ids(index, tab_uuid:, limit:, max_entries:)
        ids = []

        # Entries with no tab header (initial document loads, curl, health checks)
        # form their own group so they are capped rather than kept until the TTL.
        if limit.positive?
          tab_metas = index.values.select { |meta| meta['tabUuid'] == tab_uuid }
          ids |= newest_first(tab_metas).drop(limit).map { |meta| meta['id'] }
        end

        ids |= newest_first(index.values).drop(max_entries).map { |meta| meta['id'] } if max_entries.positive?
        ids
      end

      def remove_entry_files(ids)
        ids.each { |id| FileUtils.rm_f(entry_path(id)) if Ulid.valid?(id) }
      end

      def read_index
        index = parse_index(read_raw_index)
        return normalize_index(index) if index

        rebuild_index_from_files
      end

      def normalize_index(index)
        index.each_with_object({}) do |(id, meta), normalized|
          normalized[id] = index_meta(meta) if meta.is_a?(Hash)
        end
      end

      # Rebuild under the lock and reuse the index `mutate_index` already read there,
      # so a concurrent write is not clobbered by a snapshot taken before it landed.
      # An entry dropped that way would be invisible to `all` and, since `prune` only
      # deletes ids listed in the index, would never be reclaimed.
      def rebuild_index_from_files
        rebuilt = {}
        mutate_index { |index| rebuilt = normalize_index(index) }
        rebuilt
      end

      def read_json(path)
        parsed = JSON.parse(File.read(path))
        parsed if parsed.is_a?(Hash)
      rescue SystemCallError, JSON::ParserError
        nil
      end

      def read_last_pruned_at
        Integer(File.read(File.join(@path, LAST_PRUNE_FILE)), exception: false)
      rescue SystemCallError
        nil
      end

      def mutate_index
        ensure_directory

        File.open(File.join(@path, LOCK_FILE), File::WRONLY | File::CREAT, 0o600) do |lock|
          lock.flock(File::LOCK_EX)

          index = parse_index(read_raw_index) || meta_from_files
          index = yield(index)

          write_atomically(index_path, JSON.generate(index))
        end
      end

      def read_raw_index
        File.read(index_path)
      rescue SystemCallError
        nil
      end

      def parse_index(contents)
        return if contents.nil? || contents.empty?

        parsed = JSON.parse(contents)
        parsed.is_a?(Hash) ? parsed : nil
      rescue JSON::ParserError
        nil
      end

      def meta_from_files
        Dir.glob(File.join(@path, '*.json')).each_with_object({}) do |file, index|
          next if File.basename(file) == INDEX_FILE

          meta = read_json(file)&.[]('__meta')
          index[meta['id']] = index_meta(meta) if meta.is_a?(Hash) && meta['id']
        end
      end

      def write_atomically(path, contents)
        File.atomic_write(path) { |file| file.write(contents) }
      end

      def ensure_directory
        FileUtils.mkdir_p(@path, mode: 0o700)
        gitignore = File.join(@path, '.gitignore')
        File.write(gitignore, "*\n") unless File.exist?(gitignore)
      end
    end
  end
end
