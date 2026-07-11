# frozen_string_literal: true

module InertiaRails
  # Decides whether the XSRF-TOKEN cookie rewrite can be skipped under the `:lazy` refresh policy.
  class XsrfCookieRefreshPolicy
    def self.skip?(controller)
      new(controller).skip?
    end

    def initialize(controller)
      @controller = controller
      @request = controller.request
    end

    def skip?
      return false unless configuration.xsrf_cookie_refresh == :lazy
      return false unless @request.get? || @request.head?

      cookie = @request.cookies['XSRF-TOKEN']
      return false if cookie.blank?

      return true unless can_validate_without_loading_session?

      valid_for_session?(cookie)
    end

    private

    def configuration
      @controller.send(:inertia_configuration)
    end

    def can_validate_without_loading_session?
      csrf_token_loaded_in_env? ||
        (@request.session.respond_to?(:loaded?) && @request.session.loaded?)
    end

    def valid_for_session?(cookie)
      csrf_token_was_loaded = csrf_token_loaded_in_env?
      @controller.send(:valid_authenticity_token?, @request.session, cookie)
    ensure
      # `valid_authenticity_token?` memoizes the real token into
      # `request.env[CSRF_TOKEN]` (Rails 7.1+), and the session middleware later
      # persists whatever sits there via `commit_csrf_token`. Drop the key when
      # validation itself created it, so a validation-only read can't dirty the
      # session and emit a session Set-Cookie. No-op on Rails < 7.1, where
      # there is no env key to clean up.
      @request.env.delete(csrf_token_env_key) if csrf_token_env_key && !csrf_token_was_loaded
    end

    def csrf_token_loaded_in_env?
      csrf_token_env_key && @request.env.key?(csrf_token_env_key)
    end

    def csrf_token_env_key
      return @csrf_token_env_key if defined?(@csrf_token_env_key)

      @csrf_token_env_key =
        if ActionController::RequestForgeryProtection.const_defined?(:CSRF_TOKEN, false)
          ActionController::RequestForgeryProtection.const_get(:CSRF_TOKEN)
        end
    end
  end
end
