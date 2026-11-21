# frozen_string_literal: true

require 'net/http'
require 'shellwords'

Puma::Plugin.create do
  BOOT_TIMEOUT = 30 # rubocop:disable Lint/ConstantDefinitionInBlock
  STOP_GRACE = 5 # rubocop:disable Lint/ConstantDefinitionInBlock
  REAPED = :reaped # rubocop:disable Lint/ConstantDefinitionInBlock

  def start(launcher)
    @log_writer = launcher.log_writer
    @running = true
    @boot_signal = Queue.new

    in_background do
      @boot_signal.pop
      run_ssr_loop
    end

    events = launcher.events

    if events.respond_to?(:after_booted)
      events.after_booted { @boot_signal.push(true) }
      events.after_stopped { stop_ssr }
      events.before_restart { stop_ssr }
    else
      events.on_booted { @boot_signal.push(true) }
      events.on_stopped { stop_ssr }
      events.on_restart { stop_ssr }
    end
  end

  private

  def run_ssr_loop
    return if vite_dev_server_running?

    bundle = resolve_bundle
    return unless bundle

    command = [*Shellwords.split(resolve_runtime), bundle]
    uri = URI(resolve_base_url)
    consecutive_crashes = 0
    delay = 1

    while @running
      break if vite_dev_server_running?

      begin
        @pid = spawn(*command)
        # Process.detach waits in its own thread, so a child Puma's cluster master already reaped still reads as exited.
        @waiter = Process.detach(@pid)
      rescue Errno::ENOENT
        log "! Inertia SSR: '#{command.first}' not found in PATH"
        break
      end

      outcome, status = wait_for_boot(uri)

      case outcome
      when :ready
        log "* Inertia SSR: server ready (pid: #{@pid})"
        consecutive_crashes = 0
        delay = 1
      when :timeout
        log "! Inertia SSR: server failed to respond within #{BOOT_TIMEOUT}s"
      end

      status ||= wait_for_exit
      break unless @running

      consecutive_crashes += 1
      if consecutive_crashes >= 10
        log '! Inertia SSR: too many crashes, giving up'
        break
      end

      log "! Inertia SSR: process exited (status: #{describe(status)}), restarting in #{delay}s..."
      sleep delay
      delay = [delay * 2, 16].min
    end
  end

  def stop_ssr
    @running = false
    return unless @pid

    request_shutdown
    wait_for_exit(STOP_GRACE) || force_kill
  rescue Errno::ESRCH
    # already exited
  ensure
    @pid = nil
  end

  # /shutdown correctly handles cluster mode
  def request_shutdown
    uri = URI(resolve_base_url)
    Net::HTTP.start(uri.host, uri.port, open_timeout: 2, read_timeout: 5) do |http|
      http.post('/shutdown', '')
    end
  rescue StandardError
    Process.kill('TERM', @pid)
  end

  def wait_for_boot(uri)
    BOOT_TIMEOUT.times do
      return [:stopping, nil] unless @running

      return [:exited, exit_status] unless @waiter.alive?

      begin
        Net::HTTP.start(uri.host, uri.port, open_timeout: 1, read_timeout: 1) do |http|
          http.get('/health')
        end
        return [:ready, nil]
      rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL, Net::OpenTimeout, Net::ReadTimeout
        sleep 1
      end
    end
    [:timeout, nil]
  end

  # Waits for the SSR process to exit, at most `seconds` when given. Returns its status, or nil while it runs.
  def wait_for_exit(seconds = nil)
    return unless @waiter.join(seconds)

    exit_status
  end

  def force_kill
    Process.kill('KILL', @pid)
    @waiter.join
    exit_status
  end

  # The process's status, or REAPED when Puma's cluster master collected it first.
  def exit_status
    @waiter.value || REAPED
  end

  def describe(status)
    return 'unknown' if REAPED.equal?(status)

    status.exitstatus || "signal #{status.termsig}"
  end

  def resolve_runtime
    InertiaRails.configuration.ssr_runtime || detect_runtime
  end

  def detect_runtime
    root = defined?(Rails) ? Rails.root : Pathname.new(Dir.pwd)
    if File.exist?(root.join('bun.lockb')) || File.exist?(root.join('bun.lock'))
      'bun'
    elsif File.exist?(root.join('deno.lock'))
      'deno'
    else
      'node'
    end
  end

  def resolve_bundle
    config = InertiaRails.configuration

    return Array(config.ssr_bundle).find { |path| File.exist?(path) } if config.ssr_bundle

    patterns = %w[ssr/*.js public/assets-ssr/*.js]
    if defined?(ViteRuby) && (ssr_dir = ViteRuby.config.ssr_output_dir)
      patterns.prepend(File.join(ssr_dir, '*.js'))
    end

    patterns.each do |pattern|
      candidates = Dir.glob(pattern)
      return candidates.first if candidates.any?
    end

    nil
  end

  def resolve_base_url
    url = InertiaRails.configuration.ssr_url
    if url
      url.sub(%r{/(render|__inertia_ssr)\z}, '')
    else
      InertiaRails::Configuration::DEFAULT_SSR_URL
    end
  end

  def vite_dev_server_running?
    InertiaRails::SSR.vite_dev_server_running?
  end

  def log(message)
    @log_writer.log(message)
  end
end
