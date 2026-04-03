# frozen_string_literal: true

require 'net/http'

Puma::Plugin.create do
  BOOT_TIMEOUT = 30 # rubocop:disable Lint/ConstantDefinitionInBlock

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
    return unless ssr_enabled?
    return if vite_dev_server_running?

    bundle = resolve_bundle
    return unless bundle

    runtime = resolve_runtime
    uri = URI(resolve_base_url)
    consecutive_crashes = 0
    delay = 1

    while @running
      break if vite_dev_server_running?

      begin
        @pid = spawn(runtime, bundle)
      rescue Errno::ENOENT
        log "! Inertia SSR: '#{runtime}' not found in PATH"
        break
      end

      if wait_for_server(uri)
        log "* Inertia SSR: server ready (pid: #{@pid})"
        consecutive_crashes = 0
        delay = 1
      else
        log "! Inertia SSR: server failed to respond within #{BOOT_TIMEOUT}s"
      end

      _, status = Process.wait2(@pid)
      break unless @running

      consecutive_crashes += 1
      if consecutive_crashes >= 10
        log '! Inertia SSR: too many crashes, giving up'
        break
      end

      log "! Inertia SSR: process exited (status: #{status.exitstatus}), restarting in #{delay}s..."
      sleep delay
      delay = [delay * 2, 16].min
    end
  end

  def stop_ssr
    @running = false
    return unless @pid

    Process.waitpid(@pid, Process::WNOHANG)

    # /shutdown correctly handles cluster mode
    begin
      uri = URI(resolve_base_url)
      Net::HTTP.start(uri.host, uri.port, open_timeout: 2, read_timeout: 5) do |http|
        http.post('/shutdown', '')
      end
      Process.wait(@pid)
    rescue StandardError
      Process.kill('TERM', @pid)
      Process.wait(@pid)
    end
  rescue Errno::ESRCH, Errno::ECHILD
    # already exited
  ensure
    @pid = nil
  end

  def wait_for_server(uri) # rubocop:disable Naming/PredicateMethod
    BOOT_TIMEOUT.times do
      return false unless @running

      begin
        Net::HTTP.start(uri.host, uri.port, open_timeout: 1, read_timeout: 1) do |http|
          http.get('/health')
        end
        return true
      rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL, Net::OpenTimeout, Net::ReadTimeout
        sleep 1
      end
    end
    false
  end

  def ssr_enabled?
    InertiaRails.configuration.ssr_enabled
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

    if defined?(ViteRuby)
      ssr_dir = ViteRuby.config.ssr_output_dir
      candidates = Dir.glob(File.join(ssr_dir, 'inertia.*')) if ssr_dir
      return candidates.first if candidates&.any?
    end

    path = 'public/assets-ssr/inertia.js'
    path if File.exist?(path)
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
