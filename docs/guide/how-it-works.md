# How it works

With Inertia you build applications just like you've always done with your server-side web framework of choice. You use your framework's existing functionality for routing, controllers, middleware, authentication, authorization, data fetching, and more.

However, Inertia replaces your application's view layer. Instead of using server-side rendering via PHP or Ruby templates, the views returned by your application are JavaScript page components. This allows you to build your entire frontend using React, Vue, or Svelte, while still enjoying the productivity of Laravel or your preferred server-side framework.

As you might expect, simply creating your frontend in JavaScript doesn't give you a single-page application experience. If you were to click a link, your browser would make a full page visit, which would then cause your client-side framework to reboot on the subsequent page load. This is where Inertia changes everything.

At its core, Inertia is essentially a client-side routing library. It allows you to make page visits without forcing a full page reload. This is done using the `<Link>` component, a light-weight wrapper around a normal anchor link. When you click an Inertia link, Inertia intercepts the click and makes the visit via XHR instead. You can even make these visits programmatically in JavaScript using `router.visit()`.

When Inertia makes an XHR visit, the server detects that it's an Inertia visit and, instead of returning a full HTML response, it returns a JSON response with the JavaScript page component name and data (props). Inertia then dynamically swaps out the previous page component with the new page component and updates the browser's history state.

**The end result is a silky smooth single-page experience. 🎉**

To learn more about the nitty-gritty, technical details of how Inertia works under the hood, check out [the protocol page](/guide/the-protocol.md).
