# frozen_string_literal: true

module InertiaRails
  module LiveBroadcast
    SOCKET_ID_HEADER = 'X-Socket-Id'

    class << self
      def broadcast(live, props: nil, to_others: false)
        raise ArgumentError, '`props:` must be a hash of prop names to values' unless props.nil? || props.is_a?(Hash)

        publish(LiveStream.names(live), props: props && pushed(props), socket_id: to_others ? current_socket_id : nil)
      end

      # Stream names are computed now, so a destroyed record still broadcasts from the job.
      def broadcast_later(live, to_others: false)
        LiveBroadcastJob.perform_later(LiveStream.names(live), to_others ? current_socket_id : nil)
      end

      def publish(names, props: nil, socket_id: nil)
        message = { '__inertia' => { 'event' => LiveStream::EVENT, 'socketId' => socket_id, 'props' => props }.compact }
        names.each { |name| ActionCable.server.broadcast(name, message) }
      end

      private

      def current_socket_id
        Current.request&.headers&.[](SOCKET_ID_HEADER)
      end

      # Like a page, with the global settings: a controller's `inertia_config` is out of reach here.
      def pushed(props)
        props = InertiaRails.configuration.prop_transformer(props: resolve(props))
        InertiaRails.configuration.preserve_big_integers ? BigIntegers.encode(props) : props
      end

      # Keys stay literal: the client writes "order.total" by path, and only for props it listens to.
      def resolve(value)
        case value
        when BaseProp then raise ArgumentError, 'Broadcast props take values, not prop types'
        when Hash then value.transform_values { |inner| resolve(inner) }
        when Array then value.map { |inner| resolve(inner) }
        else PropsResolver.serializer?(value) ? resolve(value.to_inertia) : value
        end
      end
    end
  end
end
