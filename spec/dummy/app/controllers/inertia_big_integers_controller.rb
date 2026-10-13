# frozen_string_literal: true

class InertiaBigIntegersController < ApplicationController
  BIG = 900_719_925_474_099_988

  inertia_config(preserve_big_integers: -> { action_name == 'enabled' })

  def enabled
    flash.now.inertia[:created_id] = BIG
    cached = InertiaRails.cache('big_integers/cached') { { id: BIG } }
    cursors = { page_name: 'cursor', previous_page: nil, next_page: BIG + 1, current_page: BIG }
    posts = InertiaRails.scroll(cursors) { [] }
    render inertia: 'TestComponent', props: { big: BIG, cached: cached, posts: posts }
  end

  def disabled
    render inertia: 'TestComponent', props: { big: BIG }
  end

  def enabled_for_render
    render inertia: 'TestComponent', props: { big: BIG }, preserve_big_integers: true
  end
end
