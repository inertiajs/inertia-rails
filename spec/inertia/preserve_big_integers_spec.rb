# frozen_string_literal: true

require_relative '../../lib/inertia_rails/rspec'

RSpec.describe 'Preserving big integers', type: :request do
  let(:headers) { { 'X-Inertia' => true } }
  let(:big) { InertiaBigIntegersController::BIG }
  let(:marker) { { '$bigint' => '900719925474099988' } }
  let(:next_cursor) { '900719925474099989' }

  it 'wraps big integers in props, flash and scroll metadata, and flags the page' do
    get big_integers_enabled_path, headers: headers

    expect(response.parsed_body).to include(
      'props' => include('big' => marker, 'cached' => { 'id' => marker }),
      'flash' => { 'created_id' => marker },
      'scrollProps' => { 'posts' => include('currentPage' => marker, 'nextPage' => { '$bigint' => next_cursor }) },
      'preserveBigIntegers' => true
    )
  end

  it 'decodes the markers in the test helpers' do
    get big_integers_enabled_path, headers: headers

    expect(inertia.props[:big]).to eq(big)
    expect(inertia.flash[:created_id]).to eq(big)
  end

  it 'sends plain numbers without the flag when disabled' do
    get big_integers_disabled_path, headers: headers

    expect(response.parsed_body['props']['big']).to eq(big)
    expect(response.parsed_body).not_to have_key('preserveBigIntegers')
  end

  it 'can be enabled for a single render' do
    get big_integers_enabled_for_render_path, headers: headers

    expect(response.parsed_body['props']['big']).to eq(marker)
  end
end
