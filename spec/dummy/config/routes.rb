Rails.application.routes.draw do
  mount InertiaRails::Engine => "/inertia-rails"

  get 'props' => 'inertia_render_test#props'
  get 'view_data' => 'inertia_render_test#view_data'
  get 'component' => 'inertia_render_test#component'
  get 'share' => 'inertia_share_test#share'
  get 'share_with_inherited' => 'inertia_child_share_test#share_with_inherited'
  get 'empty_test' => 'inertia_test#empty_test'
  get 'redirect_test' => 'inertia_test#redirect_test'
  get 'inertia_request_test' => 'inertia_test#inertia_request_test'
  get 'inertia_partial_request_test' => 'inertia_test#inertia_partial_request_test'
  post 'redirect_test' => 'inertia_test#redirect_test'
  patch 'redirect_test' => 'inertia_test#redirect_test'
  put 'redirect_test' => 'inertia_test#redirect_test'
  delete 'redirect_test' => 'inertia_test#redirect_test'
  get 'my_location' => 'inertia_test#my_location'
  get 'share_multithreaded' => 'inertia_multithreaded_share#share_multithreaded'
  get 'content_type_test' => 'inertia_test#content_type_test'
end
