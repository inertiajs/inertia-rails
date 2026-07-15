# frozen_string_literal: true

RSpec.describe 'conditional GET variant split', type: :request do
  def get_etag(path, headers = {})
    get path, headers: headers
    response.headers['ETag']
  end

  let(:partial_headers) do
    {
      'X-Inertia' => 'true',
      'X-Inertia-Partial-Data' => 'name',
      'X-Inertia-Partial-Component' => 'TestComponent',
    }
  end

  describe 'HTML vs Inertia JSON' do
    it 'gives the two variants different ETags' do
      html = get_etag(conditional_get_path)
      json = get_etag(conditional_get_path, 'X-Inertia' => 'true')

      expect(html).to be_present
      expect(json).to be_present
      expect(html).not_to eq(json)
    end

    it 'does not serve a wrong-variant 304' do
      html = get_etag(conditional_get_path)

      get conditional_get_path, headers: { 'X-Inertia' => 'true', 'If-None-Match' => html }

      expect(response.status).to eq(200)
      expect(response.headers['X-Inertia']).to eq('true')
    end

    it 'still 304s a matching Inertia conditional GET' do
      json = get_etag(conditional_get_path, 'X-Inertia' => 'true')
      get conditional_get_path, headers: { 'X-Inertia' => 'true', 'If-None-Match' => json }
      expect(response.status).to eq(304)
    end

    it 'leaves the plain (non-Inertia) conditional GET working unchanged' do
      html = get_etag(conditional_get_path)
      get conditional_get_path, headers: { 'If-None-Match' => html }
      expect(response.status).to eq(304)
    end

    it 'keeps Vary: X-Inertia on the rendered 200 (existing renderer behavior)' do
      get conditional_get_path
      expect(response.headers['Vary'].to_s).to match(/\bX-Inertia\b/)
    end
  end

  describe 'full visit vs partial reload (same URL, different body)' do
    it 'gives a partial reload a different ETag than a full visit' do
      full = get_etag(conditional_partial_path, 'X-Inertia' => 'true')
      partial = get_etag(conditional_partial_path, partial_headers)

      expect(full).not_to eq(partial)
    end

    it 'does not serve the full-visit body to a partial conditional GET' do
      full = get_etag(conditional_partial_path, 'X-Inertia' => 'true')

      get conditional_partial_path, headers: partial_headers.merge('If-None-Match' => full)

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['props'].keys).to eq(['name'])
    end

    it 'still 304s a matching partial conditional GET' do
      partial = get_etag(conditional_partial_path, partial_headers)
      get conditional_partial_path, headers: partial_headers.merge('If-None-Match' => partial)
      expect(response.status).to eq(304)
    end
  end

  describe 'body-affecting protocol headers beyond partial reloads' do
    it 'gives a resetting partial reload a different ETag than a plain one' do
      plain = get_etag(conditional_partial_path, partial_headers)
      reset = get_etag(conditional_partial_path, partial_headers.merge('X-Inertia-Reset' => 'name'))

      expect(plain).not_to eq(reset)
    end

    it 'gives a request skipping once props a different ETag than a full visit' do
      full = get_etag(conditional_get_path, 'X-Inertia' => 'true')
      except_once = get_etag(conditional_get_path, 'X-Inertia' => 'true', 'X-Inertia-Except-Once-Props' => 'name')

      expect(full).not_to eq(except_once)
    end
  end

  describe 'other conditional-GET forms' do
    it 'splits variants for strong_etag too' do
      html = get_etag(conditional_strong_path)
      json = get_etag(conditional_strong_path, 'X-Inertia' => 'true')
      expect(html).not_to eq(json)

      get conditional_strong_path, headers: { 'X-Inertia' => 'true', 'If-None-Match' => html }
      expect(response.status).to eq(200)
    end

    it 'splits variants for stale? block form' do
      html = get_etag(conditional_stale_path)
      json = get_etag(conditional_stale_path, 'X-Inertia' => 'true')
      expect(html).not_to eq(json)

      get conditional_stale_path, headers: { 'X-Inertia' => 'true', 'If-None-Match' => html }
      expect(response.status).to eq(200)
    end
  end

  describe 'known limitation: last_modified-only conditional GET' do
    # With no ETag there is no validator to fold the variant into, so the
    # split cannot apply; pair last_modified with an etag to stay covered.
    it 'wrong-serves a 304 across variants' do
      get conditional_last_modified_path
      last_modified = response.headers['Last-Modified']

      get conditional_last_modified_path, headers: {
        'X-Inertia' => 'true',
        'If-Modified-Since' => last_modified,
      }

      expect(response.status).to eq(304)
    end
  end
end
