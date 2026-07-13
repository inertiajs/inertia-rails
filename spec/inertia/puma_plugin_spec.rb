# frozen_string_literal: true

require 'rails_helper'
require 'net/http'
require 'timeout'

# Integration tests for the Puma SSR plugin.
# Requires `puma` gem to be available.
# Run with: bundle exec rspec spec/inertia/puma_plugin_spec.rb
RSpec.describe 'Puma Inertia SSR plugin' do
  let(:puma_port) { 9222 }
  let(:ssr_port) { 13_799 }
  let(:ssr_url) { "http://127.0.0.1:#{ssr_port}" }
  let(:puma_config_dir) { Rails.root.join('tmp/puma_plugin_test') }

  def write_puma_config(extra = '')
    FileUtils.mkdir_p(puma_config_dir)
    File.write(puma_config_dir.join('puma.rb'), <<~RUBY)
      require "logger"
      plugin :inertia_ssr
      bind "tcp://127.0.0.1:#{puma_port}"
      threads 1, 1
      workers 0
      #{extra}
    RUBY
  end

  def write_ssr_bundle(port: ssr_port)
    FileUtils.mkdir_p(puma_config_dir)
    # Minimal Node.js HTTP server that mimics Inertia SSR endpoints
    File.write(puma_config_dir.join('ssr.js'), <<~JS)
      const http = require('http');
      const server = http.createServer((req, res) => {
        if (req.url === '/health') {
          res.writeHead(200, {'Content-Type': 'application/json'});
          res.end(JSON.stringify({status: 'OK', timestamp: Date.now()}));
        } else if (req.url === '/render') {
          let body = '';
          req.on('data', c => body += c);
          req.on('end', () => {
            res.writeHead(200, {'Content-Type': 'application/json'});
            res.end(JSON.stringify({body: '<div>SSR</div>', head: ['<title>SSR</title>']}));
          });
        } else if (req.url === '/shutdown') {
          res.writeHead(200, {'Content-Type': 'application/json'});
          res.end(JSON.stringify({status: 'shutting down'}));
          process.exit(0);
        } else {
          res.writeHead(404);
          res.end();
        }
      });
      server.listen(#{port}, '127.0.0.1', () => {
        console.log('Test SSR server listening on port #{port}');
      });
    JS
    puma_config_dir.join('ssr.js').to_s
  end

  def start_puma(env: {})
    Dir.chdir(Rails.root) do
      @puma_pid = spawn(
        env,
        'bundle', 'exec', 'puma',
        '-C', puma_config_dir.join('puma.rb').to_s,
        'config.ru',
        %i[out err] => puma_config_dir.join('puma.log').to_s
      )
    end
    wait_for_port(puma_port, timeout: 15)
  end

  def stop_puma
    return unless @puma_pid

    Process.kill('INT', @puma_pid)
    Timeout.timeout(10) { Process.wait(@puma_pid) }
  rescue Errno::ESRCH, Errno::ECHILD
    # already exited
  ensure
    @puma_pid = nil
  end

  def puma_log
    log_path = puma_config_dir.join('puma.log')
    File.exist?(log_path) ? File.read(log_path) : ''
  end

  def wait_for_port(port, timeout: 10)
    deadline = Time.now + timeout
    loop do
      TCPSocket.new('127.0.0.1', port).close
      return true
    rescue Errno::ECONNREFUSED
      raise "Port #{port} not open after #{timeout}s\nPuma log:\n#{puma_log}" if Time.now > deadline

      sleep 0.2
    end
  end

  def port_open?(port)
    TCPSocket.new('127.0.0.1', port).close
    true
  rescue Errno::ECONNREFUSED
    false
  end

  def wait_for_port_closed(port, timeout: 10)
    deadline = Time.now + timeout
    loop do
      return true unless port_open?(port)
      raise "Port #{port} still open after #{timeout}s" if Time.now > deadline

      sleep 0.2
    end
  end

  after do
    stop_puma
    FileUtils.rm_rf(puma_config_dir)
  end

  context 'when SSR is enabled with a valid bundle' do
    it 'starts the SSR server alongside Puma and stops it on shutdown' do
      bundle = write_ssr_bundle
      write_puma_config

      start_puma(env: {
                   'INERTIA_SSR_ENABLED' => 'true',
                   'INERTIA_SSR_URL' => ssr_url,
                   'INERTIA_SSR_BUNDLE' => bundle,
                 })

      # SSR server should be up
      wait_for_port(ssr_port, timeout: 35)
      response = Net::HTTP.get_response(URI("#{ssr_url}/health"))
      expect(response.code).to eq('200')
      body = JSON.parse(response.body)
      expect(body['status']).to eq('OK')

      # Stop Puma — SSR should stop too
      stop_puma
      wait_for_port_closed(ssr_port)
    end
  end

  context 'when SSR is disabled' do
    it 'does not start the SSR server' do
      bundle = write_ssr_bundle
      write_puma_config

      start_puma(env: {
                   'INERTIA_SSR_ENABLED' => 'false',
                   'INERTIA_SSR_URL' => ssr_url,
                   'INERTIA_SSR_BUNDLE' => bundle,
                 })

      # Puma is up but SSR should not be
      sleep 2
      expect(port_open?(ssr_port)).to be false
    end
  end

  context 'when SSR bundle does not exist' do
    it 'does not start the SSR server' do
      write_puma_config

      start_puma(env: {
                   'INERTIA_SSR_ENABLED' => 'true',
                   'INERTIA_SSR_URL' => ssr_url,
                   'INERTIA_SSR_BUNDLE' => '/nonexistent/ssr.js',
                 })

      sleep 2
      expect(port_open?(ssr_port)).to be false
    end
  end

  context 'when the SSR process crashes' do
    it 'restarts the SSR server automatically' do
      bundle = write_ssr_bundle
      write_puma_config

      start_puma(env: {
                   'INERTIA_SSR_ENABLED' => 'true',
                   'INERTIA_SSR_URL' => ssr_url,
                   'INERTIA_SSR_BUNDLE' => bundle,
                 })

      wait_for_port(ssr_port, timeout: 35)

      # Kill the SSR process via /shutdown
      Net::HTTP.post(URI("#{ssr_url}/shutdown"), '')

      # Wait for it to come back
      wait_for_port_closed(ssr_port)
      wait_for_port(ssr_port, timeout: 35)

      response = Net::HTTP.get_response(URI("#{ssr_url}/health"))
      expect(response.code).to eq('200')
    end
  end
end
