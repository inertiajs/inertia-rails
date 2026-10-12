# frozen_string_literal: true

# The dummy app renders error pages with ExceptionsAppErrorsController;
# examples pass another exceptions app in the `dummy.exceptions_app` env key.
RSpec.describe InertiaRails::ExceptionsApp, type: :request do
  let(:inertia_headers) do
    { 'X-Inertia' => 'true', 'X-Requested-With' => 'XMLHttpRequest', 'Accept' => 'text/html, application/xhtml+xml' }
  end
  let(:html_headers) { { 'Accept' => 'text/html' } }

  # Production settings: rescue every exception, no debug pages.
  around do |example|
    env_config = Rails.application.env_config
    original = env_config.slice('action_dispatch.show_exceptions', 'action_dispatch.show_detailed_exceptions')
    env_config['action_dispatch.show_exceptions'] = Rails.version < '7.1' ? true : :all
    env_config['action_dispatch.show_detailed_exceptions'] = false
    example.run
  ensure
    env_config.merge!(original)
  end

  def html_page
    JSON.parse(Nokogiri::HTML(response.body).at_css('[data-page]')['data-page'])
  end

  def public_page(status)
    Rails.public_path.join("#{status}.html").read
  end

  it 'renders the page with the error status as HTML' do
    get '/exceptions_app/missing', headers: html_headers

    expect(response).to have_http_status(:not_found)
    expect(html_page).to include(
      'component' => 'ErrorPage',
      'props' => { 'status' => 404 },
      'url' => '/exceptions_app/missing'
    )
  end

  it 'renders the page as Inertia JSON for Inertia requests' do
    get '/exceptions_app/boom', headers: inertia_headers

    expect(response).to have_http_status(:internal_server_error)
    expect(response.headers['X-Inertia']).to eq('true')
    expect(response.parsed_body).to include('component' => 'ErrorPage', 'props' => { 'status' => 500 })
  end

  it 'keeps Rails’ JSON response for JSON requests' do
    get '/exceptions_app/boom', headers: { 'Accept' => 'application/json' }

    expect(response).to have_http_status(:internal_server_error)
    expect(response.parsed_body).to eq('status' => 500, 'error' => 'Internal Server Error')
  end

  it 'renders pages for the listed statuses only' do
    errors_app = described_class.new(controller: 'ExceptionsAppErrorsController', statuses: %i[not_found])

    get '/exceptions_app/missing', headers: inertia_headers, env: { 'dummy.exceptions_app' => errors_app }
    expect(response.parsed_body).to include('component' => 'ErrorPage', 'props' => { 'status' => 404 })

    get '/exceptions_app/boom', headers: inertia_headers, env: { 'dummy.exceptions_app' => errors_app }
    expect(response).to have_http_status(:internal_server_error)
    expect(response.body).to eq(public_page(500))
  end

  it 'asks an Inertia client with stale assets to reload' do
    get '/exceptions_app/boom', headers: inertia_headers.merge('X-Inertia-Version' => 'stale')

    expect(response).to have_http_status(:conflict)
    expect(response.headers['X-Inertia-Location']).to eq('http://www.example.com/exceptions_app/boom')
  end
end
