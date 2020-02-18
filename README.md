# Inertia.js Rails Adapter

Visit [inertiajs.com](https://inertiajs.com/) to learn more.

# Note to pre Rubygems release users

The initial version of the gem was named `inertia`; however, that name was not available on Rubygems. 

The 1.0.0 version release on Rubygems is `inertia_rails`.

The changes required are:

1. Use `gem 'inertia_rails'` in your Gemfile (or `gem install inertia_rails`)
2. Change any `Inertia.configure` calls to `InertiaRails.configure`
