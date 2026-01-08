# frozen_string_literal: true

require 'test_helper'

class InertiaMinitestTest < ActionDispatch::IntegrationTest
  # No setup block needed - auto-setup when helpers are included!

  # Inertia response assertion

  test 'assert_inertia_response works for inertia responses' do
    get props_path
    assert_inertia_response
  end

  test 'refute_inertia_response works for non-inertia responses' do
    get non_inertiafied_path
    refute_inertia_response
  end

  # Component assertions

  test 'assert_inertia_component works' do
    get props_path
    assert_inertia_component 'TestComponent'
  end

  test 'assert_inertia_props works with partial match' do
    get props_path
    assert_inertia_props name: 'Brandon'
  end

  test 'assert_inertia_props_equal works with exact match' do
    get props_path
    assert_inertia_props_equal name: 'Brandon', sport: 'hockey'
  end

  test 'refute_inertia_props_equal works when props do not match exactly' do
    get props_path
    refute_inertia_props_equal name: 'Brandon'
    refute_inertia_props_equal name: 'Brandon', sport: 'hockey', extra: 'key'
  end

  test 'assert_inertia_view_data works with partial match' do
    get view_data_path
    assert_inertia_view_data name: 'Brian'
  end

  test 'assert_inertia_view_data_equal works with exact match' do
    get view_data_path
    assert_inertia_view_data_equal name: 'Brian', sport: 'basketball'
  end

  test 'refute_inertia_view_data_equal works when view_data does not match exactly' do
    get view_data_path
    refute_inertia_view_data_equal name: 'Brian'
    refute_inertia_view_data_equal name: 'Brian', sport: 'basketball', extra: 'key'
  end

  test 'refute_inertia_view_data works for partial match negation' do
    get view_data_path
    refute_inertia_view_data name: 'NotBrian'
    refute_inertia_view_data secret: 'value'
  end

  test 'assert_no_inertia_prop works' do
    get props_path
    assert_no_inertia_prop :secret
    assert_no_inertia_prop :nonexistent
  end

  test 'refute_inertia_props works for partial match negation' do
    get props_path
    refute_inertia_props name: 'NotBrandon'
    refute_inertia_props secret: 'value'
  end

  test 'refute_inertia_component works' do
    get props_path
    refute_inertia_component 'WrongComponent'
  end

  test 'inertia helper returns response directly' do
    get props_path
    assert_equal 'TestComponent', inertia.component
    assert_equal 'Brandon', inertia.props[:name]
    assert_equal 'hockey', inertia.props[:sport]
  end

  test 'sequential inertia request works with symbol keys' do
    get props_path, headers: { 'X-Inertia' => 'true' }
    assert_inertia_component 'TestComponent'
    assert_equal 'Brandon', inertia.props[:name]
    assert_equal 'hockey', inertia.props[:sport]
  end

  test 'sequential inertia request works with string keys (indifferent access)' do
    get props_path, headers: { 'X-Inertia' => 'true' }
    assert_inertia_component 'TestComponent'
    assert_equal 'Brandon', inertia.props['name']
    assert_equal 'hockey', inertia.props['sport']
  end

  # Flash assertions

  test 'assert_inertia_flash works with partial match' do
    get render_with_inertia_flash_method_path
    assert_inertia_flash success: 'Item saved!'
  end

  test 'assert_inertia_flash_equal works with exact match' do
    get render_with_inertia_flash_method_path
    assert_inertia_flash_equal success: 'Item saved!', notice: 'Changes applied'
  end

  test 'refute_inertia_flash_equal works when flash does not match exactly' do
    get render_with_inertia_flash_method_path
    refute_inertia_flash_equal success: 'Item saved!'
    refute_inertia_flash_equal success: 'Item saved!', notice: 'Changes applied', extra: 'key'
  end

  test 'assert_no_inertia_flash works' do
    get render_with_inertia_flash_method_path
    assert_no_inertia_flash :nonexistent
  end

  test 'refute_inertia_flash works for partial match negation' do
    get render_with_inertia_flash_method_path
    refute_inertia_flash success: 'wrong_value'
    refute_inertia_flash nonexistent: 'value'
  end

  test 'inertia.flash returns flash data directly' do
    get render_with_inertia_flash_method_path
    assert_equal 'Item saved!', inertia.flash[:success]
    assert_equal 'Changes applied', inertia.flash[:notice]
  end

  test 'flash.now data is accessible' do
    get render_with_inertia_flash_now_path
    assert_inertia_flash temporary: 'current request only'
  end

  # Deferred props assertions

  test 'assert_inertia_deferred_props works for presence check' do
    get deferred_props_path
    assert_inertia_deferred_props
  end

  test 'assert_inertia_deferred_props works for props in default group' do
    get deferred_props_path
    assert_inertia_deferred_props :level
    assert_inertia_deferred_props :level, :grit
  end

  test 'assert_inertia_deferred_props works with explicit group option' do
    get deferred_props_path
    assert_inertia_deferred_props :sport, group: :other
  end

  test 'refute_inertia_deferred_props works for nonexistent prop' do
    get deferred_props_path
    refute_inertia_deferred_props :nonexistent
  end

  test 'refute_inertia_deferred_props works when prop not in group' do
    get deferred_props_path
    # :sport is in :other group, not :default
    refute_inertia_deferred_props :sport
    refute_inertia_deferred_props :level, group: :other
  end

  test 'inertia.deferred_props returns deferred props directly' do
    get deferred_props_path
    assert_includes inertia.deferred_props[:default], :level
    assert_includes inertia.deferred_props['default'], :grit
    assert_includes inertia.deferred_props[:other], :sport
  end

  test 'deferred props are not in regular props on first load' do
    get deferred_props_path
    assert_nil inertia.props[:sport]
    assert_nil inertia.props[:level]
    assert_equal 'Brian', inertia.props[:name]
  end

  # Partial reload helpers

  test 'inertia_reload_only reloads only specified props' do
    get deferred_props_path

    # Initially deferred props are not in props
    assert_nil inertia.props[:level]
    assert_nil inertia.props[:grit]

    # Reload only the level prop
    inertia_reload_only(:level)

    # Now level should be present
    assert_equal 'worse than he believes', inertia.props[:level]
    # grit was not requested so it should not be present
    assert_nil inertia.props[:grit]
  end

  test 'inertia_reload_only reloads multiple props at once' do
    get deferred_props_path

    inertia_reload_only(:level, :grit)

    assert_equal 'worse than he believes', inertia.props[:level]
    assert_equal 'intense', inertia.props[:grit]
  end

  test 'inertia_reload_except reloads all props except specified ones' do
    get deferred_props_path

    # Reload all props except level
    inertia_reload_except(:level)

    # name and grit should be present, but not level
    assert_equal 'Brian', inertia.props[:name]
    assert_equal 'intense', inertia.props[:grit]
    assert_nil inertia.props[:level]
  end

  test 'inertia_load_deferred_props loads deferred props from a specific group' do
    get deferred_props_path

    # Load only the 'other' group (contains :sport)
    inertia_load_deferred_props('other')

    assert_equal 'basketball', inertia.props[:sport]
    # Props from default group should not be loaded
    assert_nil inertia.props[:level]
  end

  test 'inertia_load_deferred_props loads all deferred props when no group specified' do
    get deferred_props_path

    # Load all deferred props
    inertia_load_deferred_props

    assert_equal 'basketball', inertia.props[:sport]
    assert_equal 'worse than he believes', inertia.props[:level]
    assert_equal 'intense', inertia.props[:grit]
  end

  test 'inertia_load_deferred_props does nothing when group does not exist' do
    get deferred_props_path

    original_props = inertia.props.dup
    inertia_load_deferred_props(:nonexistent_group)

    # Props should remain unchanged
    assert_equal original_props, inertia.props
  end

  # Block-based assertions

  test 'assert_inertia_props works with block' do
    get props_path
    assert_inertia_props { |props| props[:name] == 'Brandon' && props[:sport] == 'hockey' }
  end

  test 'assert_inertia_props block fails when block returns false' do
    get props_path
    error = assert_raises(Minitest::Assertion) do
      assert_inertia_props { |props| props[:name] == 'Wrong' }
    end
    assert_match(/props block validation failed/, error.message)
  end

  test 'refute_inertia_props works with block' do
    get props_path
    refute_inertia_props { |props| props[:name] == 'NotBrandon' }
  end

  test 'assert_inertia_view_data works with block' do
    get view_data_path
    assert_inertia_view_data { |view_data| view_data[:name] == 'Brian' }
  end

  test 'refute_inertia_view_data works with block' do
    get view_data_path
    refute_inertia_view_data { |view_data| view_data[:name] == 'NotBrian' }
  end

  test 'assert_inertia_flash works with block' do
    get render_with_inertia_flash_method_path
    assert_inertia_flash { |flash| flash[:success] == 'Item saved!' }
  end

  test 'refute_inertia_flash works with block' do
    get render_with_inertia_flash_method_path
    refute_inertia_flash { |flash| flash[:nonexistent].present? }
  end

  # Deprecated assertions

  test 'assert_no_inertia_props (plural, deprecated) still works but emits deprecation warning' do
    get props_path

    # Capture deprecation warnings
    warnings = []
    InertiaRails.deprecator.behavior = ->(message, _callstack, _deprecation_horizon, _gem_name) { warnings << message }

    assert_no_inertia_props :secret

    assert_equal 1, warnings.size
    assert_match(/assert_no_inertia_props.*deprecated.*assert_no_inertia_prop/, warnings.first)
  ensure
    InertiaRails.deprecator.behavior = InertiaRails.deprecator.class::DEFAULT_BEHAVIORS[:stderr]
  end
end
