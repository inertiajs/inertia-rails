# Patch BetterErrors::Middleware to render HTML for Inertia requests
#
# Original source:
# https://github.com/BetterErrors/better_errors/blob/v2.5.1/lib/better_errors/middleware.rb
#

if defined?(BetterErrors)
  BetterErrors::Middleware.class_eval do
    prepend(InertiaBetterErrors = Module.new do
      def text?(env)
        return false if env["HTTP_X_INERTIA"]

        super
      end
    end)
  end
end
