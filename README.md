# Inertia.js Rails Adapter

To use [Inertia.js](https://github.com/inertiajs/inertia) you need both a server-side adapter (like this one) as well as a client-side adapter, such as [inertia-react](https://github.com/inertiajs/inertia-react). Be sure to also follow the installation instructions for the client-side adapter you choose. This documentation will only cover the Rails adapter setup.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'inertia-rails'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install inertia-rails

## Usage

## Layouts
Inertia Rails automatically uses your default application layout. If you'd like to change that, you can do so via the Inertia config

~~~ruby
Inertia.configure do |config|
  config.layout = 'inertia' # uses layouts/inertia.html.erb
end
~~~

## Making Inertia responses

To make an Inertia response, use the inertia renderer. This renderer takes the component name, and allows you to pass props and view_data as an options hash.

~~~ruby
class EventsController < ApplicationController
  def index
    render inertia: 'Events',
      props: {
        events: Event.all
      }
  end
end
~~~

## Following redirects

When making a non-GET Inertia request, via `<inertia-link>` or manually, be sure to still respond with a proper Inertia response. For example, if you're creating a new user, have your "store" endpoint return a redirect back to a standard GET endpoint, such as your user index page. Inertia will automatically follow this redirect and update the page accordingly. Here's a simplified example.

~~~ruby
class UsersController < ApplicationController
  def index
    render inertia: 'Users/Index', props: {users: User.all}
  end

  def store
    User.create params.require(:user).permit(:name, :email)

    redirect_to users_path
  end
end
~~~

Note, when redirecting after a `PUT`, `PATCH` or `DELETE` request you must use a `303` response code, otherwise the subsequent request will not be treated as a `GET` request. A `303` redirect is the same as a `302` except that the follow-up request is explicitly changed to a `GET` request.

## Sharing data

To share data with all your components, use the controller method `inertia_share`. This can be done both synchronously and lazily.

~~~ruby
# Synchronously
inertia_share app_name: env['app.name']

# Lazily
inertia_share do
  if logged_in?
    {
      'auth.user' => {id: logged_in_user.id}
    }
  end
end

# OR
inertia_share user_count: lambda { User.count }
~~~

## Accessing data in root template

There are situations where you may want to access your prop data in your root Blade template. For example, you may want to add a meta description tag, Twitter card meta tags, or Facebook Open Graph meta tags. These props are available via the `page` variable.

~~~erb
<meta name="twitter:title" content="<%= page['props']['event'].title %>">
~~~

Sometimes you may even want to provide data that will not be sent to your JavaScript component. You can do this using the `view_data` option.

~~~ruby
render inertia: 'Event', props: {event: event}, view_data: {meta: event.meta}
~~~

You can then access this variable like a regular erb variable.

~~~erb
<meta name="description" content="<%= meta %>">
~~~

## Asset versioning

One common challenge with single-page apps is refreshing site assets when they've been changed. Inertia makes this easy by optionally tracking the current version of your site assets. In the event that an asset changes, Inertia will automatically make a hard page visit instead of a normal ajax visit on the next request.

To enable automatic asset refreshing, first set up the Inertia config with your current asset version. We recommend putting this in an initializer.

~~~ruby
Inertia.configure do |config|
  config.version = '1.0'
end
~~~

You can also use lazy evaluation.

~~~ruby
Inertia.configure do |config|
  config.version = lambda { Version.last }
end
~~~


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/inertia-rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Inertia::Rails project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/inertia-rails/blob/master/CODE_OF_CONDUCT.md).


