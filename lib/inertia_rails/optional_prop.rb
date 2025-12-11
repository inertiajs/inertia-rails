# frozen_string_literal: true

module InertiaRails
  class OptionalProp < IgnoreOnFirstLoadProp
    prepend PropOnceable
  end
end
