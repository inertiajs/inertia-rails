module Searchable
  extend ActiveSupport::Concern

  included do
    inertia_config(raise_on_unoptimized_partial_reloads: true)

    inertia_share do
      {
        search: { query: '', results: [] }
      }
    end
  end
end
