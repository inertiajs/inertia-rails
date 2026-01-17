# frozen_string_literal: true

class MyError
  def to_hash = { uh: 'oh' }
end

class InertiaTestController < ApplicationController
  layout 'conditional', only: [:with_different_layout]

  def empty_test
    render inertia: 'EmptyTestComponent'
  end

  def with_different_layout
    render inertia: 'EmptyTestComponent'
  end

  def redirect_test
    redirect_to :empty_test
  end

  def inertia_request_test
    if request.inertia?
      head 202
    else
      head 200
    end
  end

  def inertia_partial_request_test
    if request.inertia_partial?
      head 202
    else
      head 200
    end
  end

  def non_inertiafied
    render plain: 'hey'
  end

  # Calling it my_location to avoid this in Rails 5.0
  # https://github.com/rails/rails/issues/28033
  def my_location
    inertia_location empty_test_path
  end

  def redirect_with_inertia_errors
    redirect_to empty_test_path, inertia: { errors: { uh: 'oh' } }
  end

  def redirect_with_non_hash_inertia_errors
    redirect_to empty_test_path, inertia: { errors: 'uh oh' }
  end

  def redirect_with_inertia_error_object
    redirect_to empty_test_path, inertia: { errors: MyError.new }
  end

  def redirect_back_with_inertia_errors
    redirect_back(
      fallback_location: empty_test_path,
      inertia: { errors: { go: 'back!' } }
    )
  end

  def redirect_back_or_to_with_inertia_errors
    redirect_back_or_to(
      empty_test_path,
      inertia: { errors: { go: 'back!' } }
    )
  end

  def error_404 # rubocop:disable Naming/VariableNumber
    render inertia: 'ErrorComponent', status: 404
  end

  def error_500 # rubocop:disable Naming/VariableNumber
    render inertia: 'ErrorComponent', status: 500
  end

  def content_type_test
    respond_to do |format|
      format.html { render inertia: 'EmptyTestComponent' }
      format.xml { render xml: [1, 2, 3] }
    end
  end

  def redirect_to_share_test
    redirect_to share_path
  end

  def redirect_with_inertia_flash
    redirect_to empty_test_path, flash: { inertia: { toast: 'Hello!' } }
  end

  def redirect_with_inertia_flash_and_errors
    redirect_to empty_test_path, flash: { inertia: { toast: 'Saved!' } }, inertia: { errors: { name: 'is required' } }
  end

  def double_redirect_with_flash
    flash.inertia[:first] = 'first flash'
    redirect_to redirect_with_inertia_flash_path
  end

  def render_with_inertia_flash_method
    flash.inertia[:success] = 'Item saved!'
    flash.inertia[:notice] = 'Changes applied'
    render inertia: 'EmptyTestComponent'
  end

  def render_with_inertia_flash_now
    flash.now.inertia[:temporary] = 'current request only'
    render inertia: 'EmptyTestComponent'
  end

  def redirect_with_kept_inertia_flash_now
    flash.now.inertia[:kept] = 'this was .now but kept'
    flash.keep(:inertia)
    redirect_to empty_test_path
  end

  def redirect_with_rails_notice
    redirect_to empty_test_path, notice: 'Created!'
  end

  def redirect_with_rails_alert
    redirect_to empty_test_path, alert: 'Something went wrong'
  end

  def redirect_with_mixed_flash
    flash[:notice] = 'Notice!'
    flash.inertia[:custom] = 'custom value'
    redirect_to empty_test_path
  end

  def redirect_with_non_allowlisted_key
    flash[:secret_token] = 'super_secret'
    flash[:notice] = 'Safe notice'
    redirect_to empty_test_path
  end

  def redirect_with_flash_inertia_hash
    redirect_to empty_test_path, flash: { inertia: { toast: 'Rails style!' } }
  end
end
