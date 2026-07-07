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

  def filtered_live_props
    render inertia: 'LiveTest', props: {
      tasks: InertiaRails.live(:project, on_destroy: 'Task') { [{ id: 1 }] },
      task_count: InertiaRails.live(:project) { 1 },
    }
  end

  def no_live_props
    render inertia: 'LiveTest', props: {
      tasks: -> { [{ id: 1 }] },
    }
  end

  def live_request_id_echo
    render plain: InertiaRails::Current.live_request_id.to_s
  end

  def create_task
    redirect_to live_props_path
  end
end
