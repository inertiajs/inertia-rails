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

  test 'assert_inertia_view_data works with partial match' do
    get view_data_path
    assert_inertia_view_data name: 'Brian'
  end

  test 'assert_inertia_view_data_equal works with exact match' do
    get view_data_path
    assert_inertia_view_data_equal name: 'Brian', sport: 'basketball'
  end

  test 'assert_no_inertia_prop works' do
    get props_path
    assert_no_inertia_prop :secret
    assert_no_inertia_prop :nonexistent
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
    assert_inertia_flash foo: 'bar'
  end

  test 'assert_inertia_flash_equal works with exact match' do
    get render_with_inertia_flash_method_path
    assert_inertia_flash_equal foo: 'bar', baz: 'qux'
  end

  test 'assert_no_inertia_flash works' do
    get render_with_inertia_flash_method_path
    assert_no_inertia_flash :nonexistent
  end

  test 'inertia.flash returns flash data directly' do
    get render_with_inertia_flash_method_path
    assert_equal 'bar', inertia.flash[:foo]
    assert_equal 'qux', inertia.flash[:baz]
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

  test 'assert_inertia_deferred_props works for group check' do
    get deferred_props_path
    assert_inertia_deferred_props :default
    assert_inertia_deferred_props 'other'
  end

  test 'assert_inertia_deferred_props works with hash for group keys' do
    get deferred_props_path
    assert_inertia_deferred_props default: %w[level grit]
    assert_inertia_deferred_props 'other' => ['sport']
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
end
