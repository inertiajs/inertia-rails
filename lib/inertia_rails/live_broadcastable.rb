# frozen_string_literal: true

module InertiaRails
  module LiveBroadcastable
    extend ActiveSupport::Concern

    included do
      thread_mattr_accessor :suppressed_inertia_broadcasts, instance_accessor: false
    end

    class_methods do
      def inertia_broadcasts(stream = model_name.plural)
        after_create_commit -> { inertia_broadcast_later(stream) }
        after_update_commit -> { inertia_broadcast_later(self) }
        after_destroy_commit -> { inertia_broadcast_later(self) }
      end

      def inertia_broadcasts_to(stream)
        after_commit -> { inertia_broadcast_later(stream.try(:call, self) || send(stream)) }
      end

      def suppressing_inertia_broadcasts
        original = suppressed_inertia_broadcasts
        self.suppressed_inertia_broadcasts = true
        yield
      ensure
        self.suppressed_inertia_broadcasts = original
      end
    end

    private

    def inertia_broadcast_later(stream)
      LiveBroadcast.broadcast_later(stream) unless self.class.suppressed_inertia_broadcasts
    end
  end
end
