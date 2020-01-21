# Patch ActionDispatch::DebugExceptions to render HTML for Inertia requests
#
# Rails has introduced text rendering for XHR requests with Rails 4.1 and
# changed the implementation in 4.2, 5.0 and 5.1 (unchanged since then).
#
# The original source needs to be patched, so that Inertia requests are
# NOT responded with plain text, but with HTML.

if defined?(ActionDispatch::DebugExceptions)
  if ActionPack.version.to_s >= '5.1'
    require 'patches/debug_exceptions/patch-5-1'
  elsif ActionPack.version.to_s >= '5.0'
    require 'patches/debug_exceptions/patch-5-0'
  elsif ActionPack.version.to_s >= '4.2'
    require 'patches/debug_exceptions/patch-4-2'
  elsif ActionPack.version.to_s >= '4.1'
    require 'patches/debug_exceptions/patch-4-1'
  else
    # No patch required, because text rendering for
    # XHR requests was introduced with Rails 4.1:
    # https://github.com/rails/rails/pull/11960
  end
end
