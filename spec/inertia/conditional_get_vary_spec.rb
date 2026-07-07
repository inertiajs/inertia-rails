# frozen_string_literal: true

# Regression coverage for conditional-GET (304) cross-variant poisoning.
#
# The problem: different representations of the same URL (full HTML, full
# Inertia JSON, and partial reloads) can share an ETag, so a conditional GET
# carrying one representation's validator can wrong-serve a 304 for another.
# The fix: `etag { inertia_conditional_get_variant }` in the concern folds the
# representation into the validator for Inertia requests while leaving
# non-Inertia ETags untouched (combine_etags compacts the nil).
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

    it 'does NOT serve a wrong-variant 304 (poisoning prevented)' do
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

    it 'does NOT serve the full-visit body to a partial conditional GET' do
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

  describe 'KNOWN LIMITATION: last_modified-only conditional GET' do
    # With no ETag at all, there is no validator to fold the variant into, so
    # the split cannot apply. A shared cache keyed only on the URL can still
    # cross-serve variants here; the mitigation is Vary/If-None-Match, not this
    # fix. Documented so the gap is explicit, not silent.
    it 'wrong-serves a 304 across variants (fix does not cover this path)' do
      get conditional_last_modified_path # HTML, sets Last-Modified
      last_modified = response.headers['Last-Modified']

      get conditional_last_modified_path, headers: {
        'X-Inertia' => 'true',
        'If-Modified-Since' => last_modified,
      }

      expect(response.status).to eq(304) # <- the unfixed cross-variant hit
    end
  end
end
