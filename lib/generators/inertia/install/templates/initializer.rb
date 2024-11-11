# frozen_string_literal: true

InertiaRails.configure do |config|
  config.ssr_enabled = ViteRuby.config.ssr_build_enabled
  config.version = ViteRuby.digest
end
