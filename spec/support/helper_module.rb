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
end
