# frozen_string_literal: true

module HelperModule
  def with_forgery_protection
    orig = ActionController::Base.allow_forgery_protection
    begin
      ActionController::Base.allow_forgery_protection = true
      yield if block_given?
    ensure
      ActionController::Base.allow_forgery_protection = orig
    end
  end

  def with_env(**env)
    orig = ENV.to_h
    begin
      ENV.replace(env)
      yield if block_given?
    ensure
      ENV.replace(orig)
    end
  end
end
