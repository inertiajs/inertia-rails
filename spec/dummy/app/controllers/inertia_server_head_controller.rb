# frozen_string_literal: true

class InertiaServerHeadController < ApplicationController
  inertia_config(server_head: true, layout: 'meta')

  before_action do
    inertia_meta.add({ name: 'description', content: 'Inertia rules', head_key: 'first_head_key' })
  end

  def basic
    render inertia: 'TestComponent', meta: [
      { tag_name: 'title', inner_content: 'The Inertia title' },
      { http_equiv: 'content-security-policy', content: "default-src 'self';", head_key: 'csp_key' },
      { tag_name: 'script', type: 'application/ld+json',
        inner_content: { '@context': 'https://schema.org' }, head_key: 'ld_json', }
    ]
  end

  def empty
    inertia_meta.clear
    render inertia: 'TestComponent'
  end

  def collision
    render inertia: 'TestComponent', props: { head: 'an unrelated prop' }
  end

  def collision_without_meta
    inertia_meta.clear
    render inertia: 'TestComponent', props: { head: 'an unrelated prop' }
  end

  def collision_deferred
    render inertia: 'TestComponent', props: { head: InertiaRails.defer { 'deferred data' } }
  end
end
