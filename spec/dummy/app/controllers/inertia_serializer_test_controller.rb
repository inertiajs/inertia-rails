# frozen_string_literal: true

class InertiaSerializerTestController < ApplicationController
  class CourseSerializer
    def to_inertia = { title: InertiaRails.always { 'Ruby' } }
    def inertia_prop_sources = { 'title' => [__FILE__, 5] }
  end

  class CoursesSerializer
    def to_inertia = { count: 1, course: CourseSerializer.new }
    def inertia_prop_sources = { 'count' => [__FILE__, 10], 'course' => [__FILE__, 10] }
  end

  class BrokenSerializer
    def to_inertia = { count: 1 }
    def inertia_prop_sources = raise('broken sources')
  end

  class NestedUserSerializer
    def initialize(name)
      @name = name
      @password_digest = 'private password digest'
    end

    def to_inertia = { name: @name }
  end

  class RaisingSerializer
    def to_inertia = raise('unrequested serializer')
  end

  def show
    render inertia: 'Courses/Index', props: CoursesSerializer.new
  end

  def broken
    render inertia: 'Courses/Index', props: BrokenSerializer.new
  end

  def lazy
    render inertia: 'Courses/Index', props: { course: -> { CourseSerializer.new } }
  end

  def nested
    name = params.fetch(:viewer, 'Ada')
    evaluations = 0

    render inertia: 'TestComponent', props: {
      direct: { user: NestedUserSerializer.new(name) },
      always: InertiaRails.always { { user: NestedUserSerializer.new(name), users: [NestedUserSerializer.new(name)] } },
      once: InertiaRails.once { [{ user: NestedUserSerializer.new(name), evaluations: (evaluations += 1) }] },
      merged: InertiaRails.merge { [{ user: NestedUserSerializer.new(name) }] },
      deferred: InertiaRails.defer { { users: [NestedUserSerializer.new(name)] } },
      optional: InertiaRails.optional { { user: NestedUserSerializer.new(name) } },
      filtered: InertiaRails.defer { { user: NestedUserSerializer.new(name), ignored: RaisingSerializer.new } },
      rescuable: InertiaRails.defer(rescue: true) { { user: RaisingSerializer.new } },
    }
  end
end
