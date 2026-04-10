# frozen_string_literal: true

module InertiaRails
  class OptionalProp < IgnoreOnFirstLoadProp
    prepend PropOnceable
    prepend PropCacheable
  end
end
