# frozen_string_literal: true

require 'fileutils'

module InertiaRails
  module Devtools
    # One JSON file per entry plus an index of their `__meta`, so listing never
    # reads the entry files.
    class EntriesRepository
      INDEX_FILE = '_meta.json'
      LAST_PRUNE_FILE = '_last_prune'
      SUPPRESS_SECONDS = 30

      def initialize(path:, ttl_hours: 24, prune_interval: 300)
        @path = path
        @ttl_hours = ttl_hours
        @prune_interval = prune_interval
        @suppressed_until = nil
      end

      def save(id, data)
        raise ArgumentError, 'Invalid Inertia DevTools entry id.' unless Ulid.valid?(id)

        ensure_directory
        write_atomically(entry_path(id), JSON.generate(data))
        mutate_index { |index| index.merge(id => index_meta(data['__meta'] || data[:__meta] || {})) }
      end

      def get(id)
        return unless Ulid.valid?(id)

        read_json(entry_path(id))
      end

      # Entry metadata, newest first. Ids are ULIDs, so they sort by time.
      def all
        read_index.values.sort_by { |meta| meta['id'].to_s }.reverse
      end

      # Called after the response is sent, so a slow disk never delays the app.
      def record(id, data, tab_uuid: nil, limit: 100)
        return if suppressed?

        save(id, data)
        enforce_tab_limit(tab_uuid, limit) if tab_uuid && limit.positive?
        @suppressed_until = nil
      rescue StandardError => e
        Devtools.report(e) if @suppressed_until.nil?
        @suppressed_until = monotonic + SUPPRESS_SECONDS
      end

      def enforce_tab_limit(tab_uuid, limit)
        expired = read_index
                  .values
                  .select { |meta| meta['tabUuid'] == tab_uuid }
                  .sort_by { |meta| meta['id'].to_s }
                  .reverse
                  .drop(limit)
                  .map { |meta| meta['id'] }

        delete(expired)
      end

      def prune(hours = @ttl_hours)
        cutoff = Time.now.to_f - (hours * 3600)
        delete(read_index.values.select { |meta| meta['utime'].to_f < cutoff }.map { |meta| meta['id'] })
      end

      def prune_if_due
        return prune if @prune_interval <= 0

        ensure_directory
        last = read_last_pruned_at
        return if last && (Time.now.to_i - last) < @prune_interval

        prune
        write_atomically(File.join(@path, LAST_PRUNE_FILE), Time.now.to_i.to_s)
      rescue StandardError => e
        Devtools.report(e)
      end

      private

      def suppressed?
        @suppressed_until && monotonic < @suppressed_until
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

      def delete(ids)
        return if ids.empty?

        ids.each { |id| FileUtils.rm_f(entry_path(id)) if Ulid.valid?(id) }
        mutate_index { |index| index.except(*ids) }
      end

      def read_index
        read_json(index_path) || {}
      end

      def read_json(path)
        JSON.parse(File.read(path))
      rescue Errno::ENOENT, JSON::ParserError
        nil
      end

      def read_last_pruned_at
        Integer(File.read(File.join(@path, LAST_PRUNE_FILE)), exception: false)
      rescue Errno::ENOENT
        nil
      end

      def mutate_index
        ensure_directory

        File.open(index_path, File::RDWR | File::CREAT, 0o600) do |file|
          file.flock(File::LOCK_EX)
          contents = file.read
          # A corrupt index would otherwise read as empty and drop every prior
          # entry's meta on the next write. Reseed from the entry files instead.
          index = parse_index(contents) || meta_from_files
          index = yield(index)

          file.rewind
          file.truncate(0)
          file.write(JSON.generate(index))
        end
      end

      def parse_index(contents)
        return {} if contents.nil? || contents.empty?

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
        temp = "#{path}.#{Process.pid}.#{SecureRandom.hex(4)}.tmp"
        File.binwrite(temp, contents)
        File.rename(temp, path)
      ensure
        FileUtils.rm_f(temp) if temp && File.exist?(temp)
      end

      # Not memoized: the directory lives under tmp/, where anything from a
      # `rails tmp:clear` to a stray `rm -rf` can remove it mid-process.
      def ensure_directory
        FileUtils.mkdir_p(@path, mode: 0o700)
        gitignore = File.join(@path, '.gitignore')
        File.write(gitignore, "*\n") unless File.exist?(gitignore)
      end
    end
  end
end
