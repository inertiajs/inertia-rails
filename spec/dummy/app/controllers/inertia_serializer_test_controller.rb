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

  def show
    render inertia: 'Courses/Index', props: CoursesSerializer.new
  end

  def broken
    render inertia: 'Courses/Index', props: BrokenSerializer.new
  end

  def lazy
    render inertia: 'Courses/Index', props: { course: -> { CourseSerializer.new } }
  end
end
