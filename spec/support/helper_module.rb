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

  def render_view_file(view_path, **kargs)
    ActionController::Base.new.render_to_string(template: view_path, **kargs)
  end
end
