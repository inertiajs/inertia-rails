# frozen_string_literal: true

Rails.application.routes.draw do
  mount InertiaRails::Engine => '/inertia-rails'

  get 'configuration' => 'inertia_config_test#configuration'
  get 'props' => 'inertia_render_test#props'
  get 'view_data' => 'inertia_render_test#view_data'
  get 'component' => 'inertia_render_test#component'
  get 'vary_header' => 'inertia_render_test#vary_header'
  get 'share' => 'inertia_share_test#share'
  get 'share_with_inherited' => 'inertia_child_share_test#share_with_inherited'
  get 'empty_test' => 'inertia_test#empty_test'
  get 'with_different_layout' => 'inertia_test#with_different_layout'
  get 'redirect_test' => 'inertia_test#redirect_test'
  get 'inertia_request_test' => 'inertia_test#inertia_request_test'
  get 'inertia_partial_request_test' => 'inertia_test#inertia_partial_request_test'
  post 'redirect_with_responders' => 'inertia_responders_test#redirect_test'
  post 'redirect_test' => 'inertia_test#redirect_test'
  patch 'redirect_test' => 'inertia_test#redirect_test'
  put 'redirect_test' => 'inertia_test#redirect_test'
  delete 'redirect_test' => 'inertia_test#redirect_test'
  get 'my_location' => 'inertia_test#my_location'
  get 'share_multithreaded' => 'inertia_multithreaded_share#share_multithreaded'
  get 'share_multithreaded_error' => 'inertia_multithreaded_share#share_multithreaded_error'
  get 'redirect_with_inertia_errors' => 'inertia_test#redirect_with_inertia_errors'
  post 'redirect_with_inertia_errors' => 'inertia_test#redirect_with_inertia_errors'
  post 'redirect_with_inertia_error_object' => 'inertia_test#redirect_with_inertia_error_object'
  post 'redirect_with_non_hash_inertia_errors' => 'inertia_test#redirect_with_non_hash_inertia_errors'
  post 'redirect_back_with_inertia_errors' => 'inertia_test#redirect_back_with_inertia_errors'
  post 'redirect_back_or_to_with_inertia_errors' => 'inertia_test#redirect_back_or_to_with_inertia_errors'
  get 'error_404' => 'inertia_test#error_404'
  get 'error_500' => 'inertia_test#error_500'
  get 'content_type_test' => 'inertia_test#content_type_test'
  get 'lazy_props' => 'inertia_render_test#lazy_props'
  get 'optional_props' => 'inertia_render_test#optional_props'
  get 'always_props' => 'inertia_render_test#always_props'
  get 'except_props' => 'inertia_render_test#except_props'
  get 'merge_props' => 'inertia_render_test#merge_props'
  get 'deferred_props' => 'inertia_render_test#deferred_props'
  get 'shared_deferred_props' => 'inertia_render_test#shared_deferred_props'
  get 'scroll_test' => 'inertia_render_test#scroll_test'
  get 'shared_scroll_test' => 'inertia_render_test#shared_scroll_test'
  get 'prepend_merge_test' => 'inertia_render_test#prepend_merge_test'
  get 'nested_paths_test' => 'inertia_render_test#nested_paths_test'
  get 'reset_test' => 'inertia_render_test#reset_test'
  get 'once_props' => 'inertia_render_test#once_props'
  get 'once_props_with_expires_in' => 'inertia_render_test#once_props_with_expires_in'
  get 'once_props_with_custom_key' => 'inertia_render_test#once_props_with_custom_key'
  get 'deferred_once_props' => 'inertia_render_test#deferred_once_props'
  get 'shared_once_props' => 'inertia_render_test#shared_once_props'
  get 'nested_once_props' => 'inertia_render_test#nested_once_props'
  get 'multiple_once_props' => 'inertia_render_test#multiple_once_props'
  get 'once_props_not_fresh' => 'inertia_render_test#once_props_not_fresh'
  get 'once_props_fresh' => 'inertia_render_test#once_props_fresh'
  get 'once_props_fresh_and_non_fresh' => 'inertia_render_test#once_props_fresh_and_non_fresh'
  get 'non_inertiafied' => 'inertia_test#non_inertiafied'
  get 'deeply_nested_props' => 'inertia_render_test#deeply_nested_props'

  get 'instance_props_test' => 'inertia_rails_mimic#instance_props_test'
  get 'default_render_test' => 'inertia_rails_mimic#default_render_test'
  get 'transformed_default_render_test' => 'transformed_inertia_rails_mimic#render_test'
  get 'prop_transformer_test' => 'inertia_prop_transformer#just_props'
  get 'prop_transformer_with_meta_test' => 'inertia_prop_transformer#props_and_meta'
  get 'prop_transformer_no_props_test' => 'inertia_prop_transformer#no_props'
  get 'default_component_test' => 'inertia_rails_mimic#default_component_test'
  get 'default_component_with_props_test' => 'inertia_rails_mimic#default_component_with_props_test'
  get 'default_component_with_duplicated_props_test' =>
        'inertia_rails_mimic#default_component_with_duplicated_props_test'
  get 'provided_props_test' => 'inertia_rails_mimic#provided_props_test'

  post 'redirect_to_share_test' => 'inertia_test#redirect_to_share_test'

  post 'redirect_with_inertia_flash' => 'inertia_test#redirect_with_inertia_flash'
  get 'redirect_with_inertia_flash' => 'inertia_test#redirect_with_inertia_flash'
  post 'redirect_with_non_hash_inertia_flash' => 'inertia_test#redirect_with_non_hash_inertia_flash'
  post 'redirect_with_inertia_flash_and_errors' => 'inertia_test#redirect_with_inertia_flash_and_errors'
  post 'double_redirect_with_flash' => 'inertia_test#double_redirect_with_flash'
  get 'render_with_inertia_flash_method' => 'inertia_test#render_with_inertia_flash_method'

  inertia 'inertia_route' => 'TestComponent'
  inertia :inertia_route_with_default_component
  scope :scoped, as: 'scoped' do
    inertia 'inertia_route' => 'TestComponent'
  end
  namespace :namespaced do
    inertia 'inertia_route' => 'TestComponent'
  end
  resources :items do
    inertia inertia_route: 'TestComponent', on: :member
    inertia :inertia_route_with_default_component
    inertia :inertia_route_with_default_component_on_member, on: :member
    inertia :inertia_route_with_default_component_on_collection, on: :collection
    scope :scoped, as: 'scoped' do
      inertia :inertia_route_with_default_component
    end
  end

  get 'merge_shared' => 'inertia_merge_shared#merge_shared'
  get 'deep_merge_shared' => 'inertia_merge_shared#deep_merge_shared'
  get 'shallow_merge_shared' => 'inertia_merge_shared#shallow_merge_shared'
  get 'merge_instance_props' => 'inertia_merge_instance_props#merge_instance_props'

  get 'lamda_shared_props' => 'inertia_lambda_shared_props#lamda_shared_props'

  get 'initialize_session' => 'inertia_session_continuity_test#initialize_session'
  post 'submit_form_to_test_csrf' => 'inertia_session_continuity_test#submit_form_to_test_csrf'
  delete 'clear_session' => 'inertia_session_continuity_test#clear_session'

  get 'conditional_share_index' => 'inertia_conditional_sharing#index'
  get 'conditional_share_show' => 'inertia_conditional_sharing#show'
  get 'conditional_share_edit' => 'inertia_conditional_sharing#edit'
  get 'conditional_share_show_with_a_problem' => 'inertia_conditional_sharing#show_with_a_problem'

  get 'encrypt_history_default_config' => 'inertia_encrypt_history#default_config'
  get 'encrypt_history_encrypt_history' => 'inertia_encrypt_history#encrypt_history'
  get 'encrypt_history_override_config' => 'inertia_encrypt_history#override_config'
  get 'encrypt_history_clear_history' => 'inertia_encrypt_history#clear_history'
  post 'encrypt_history_clear_history_after_redirect' => 'inertia_encrypt_history#clear_history_after_redirect'

  get 'basic_meta' => 'inertia_meta#basic'
  get 'multiple_title_tags_meta' => 'inertia_meta#multiple_title_tags'
  get 'from_before_filter_meta' => 'inertia_meta#from_before_filter'
  get 'with_duplicate_head_keys_meta' => 'inertia_meta#with_duplicate_head_keys'
  get 'override_tags_from_module_meta' => 'inertia_meta#override_tags_from_module'
  get 'auto_dedup_meta' => 'inertia_meta#auto_dedup'
  get 'allowed_duplicates_meta' => 'inertia_meta#allowed_duplicates'
  get 'cleared_meta' => 'inertia_meta#cleared_meta'
  get 'meta_with_default_render' => 'inertia_meta#meta_with_default_render'
end
