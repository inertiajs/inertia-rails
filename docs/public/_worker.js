// Cloudflare Pages worker (advanced mode) that serves the compiled rbytes
// template when Thor requests it (via `rails new -m` or `rails app:template`)
// and falls through to the static docs site for browser requests.
//
// Thor sends: Accept: application/x-thor-template
//
// This file lives in docs/public so VitePress copies it into the build
// output, where Cloudflare Pages picks it up as the deployment's worker.
// _routes.json (same directory) limits worker invocations to the paths
// handled below; all other docs traffic is served statically.

const TEMPLATE_URL =
  'https://raw.githubusercontent.com/inertia-rails/generator/dist/template.rb'

async function serveTemplate() {
  const response = await fetch(TEMPLATE_URL)

  if (!response.ok) {
    return new Response('Failed to fetch template', { status: 502 })
  }

  return new Response(response.body, {
    headers: {
      'Content-Type': 'application/x-thor-template',
      'Cache-Control': 'public, max-age=300',
    },
  })
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url)
    const accept = request.headers.get('Accept') || ''

    if (url.pathname === '/template.rb') {
      return serveTemplate()
    }

    if (accept.includes('application/x-thor-template')) {
      return serveTemplate()
    }

    return env.ASSETS.fetch(request)
  },
}
