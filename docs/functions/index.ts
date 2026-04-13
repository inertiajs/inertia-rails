// Cloudflare Pages Function that serves the compiled rbytes template
// when Thor requests it (via `rails new -m` or `rails app:template`),
// and falls through to the static docs site for browser requests.
//
// Thor sends: Accept: application/x-thor-template

const TEMPLATE_URL =
  'https://raw.githubusercontent.com/inertia-rails/generator/dist/template.rb'

export const onRequest: PagesFunction = async (context) => {
  const accept = context.request.headers.get('Accept') || ''

  if (!accept.includes('application/x-thor-template')) {
    return context.next()
  }

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
