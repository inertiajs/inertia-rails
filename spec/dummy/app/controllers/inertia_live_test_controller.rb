# frozen_string_literal: true

class InertiaLiveTestController < ApplicationController
  def live_props
    render inertia: 'LiveTest', props: {
      tasks: InertiaRails.live(:project) { [{ id: 1, title: 'Task 1' }] },
    }
  end

  def multiple_live_props
    render inertia: 'LiveTest', props: {
      tasks: InertiaRails.live(:project) { [{ id: 1 }] },
      members: InertiaRails.live(:project) { [{ id: 2 }] },
      messages: InertiaRails.live(:chat) { [{ id: 3 }] },
    }
  end

  def no_live_props
    render inertia: 'LiveTest', props: {
      tasks: -> { [{ id: 1 }] },
    }
  end

  def create_task
    redirect_to live_props_path
  end
end
