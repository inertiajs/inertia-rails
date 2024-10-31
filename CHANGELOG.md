# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
## Unreleased

### Added

* Inertia Rails documentation (@skryukov)

## [3.2.0] - 2024-06-19

* Refactor the internals of shared Inertia data to use controller instance variables instead of module level variables that run a higher risk of being leaked between requests. Big thanks to @ledermann for the initial work many years ago and to @PedroAugustoRamalhoDuarte for finishing it up!
* Change the Inertia response to set the `Vary` header to `X-Inertia` instead of `Accept`, Thanks @osbre!
* Always set the `XSRF-TOKEN` in an `after_action` request instead of only on non-Inertia requests. This fixes a bug where logging out (and resetting the session) via Inertia would create a CSRF token mismatch on a subsequent Inertia request (until you manually hard refreshed the page). Thanks @jordanhiltunen!

## [3.1.4] - 2024-04-28

* Reset Inertia shared data after each RSpec example where `inertia: true` is used. Thanks @coreyaus!
* Update Github Actions workflows to use currently supported Ruby/Rails versions. Thanks @PedroAugustoRamalhoDuarte!

## [3.1.3] - 2023-11-03

* Depend on railties instead of rails so that applications which only use pieces of Rails can avoid a full Rails installation. Thanks @BenMorganMY!

## [3.1.2] - 2023-09-26

* Fix `have_exact_props` RSpec matcher in the situation where shared props are defined in a lambda that outputs a hash with symbolized keys

## [3.1.1] - 2023-08-21

* Fix broken partial reloads caused by comparing a list of symbolized keys with string keys from HashWithIndifferentAccess

## [3.1.0] - 2023-08-21

### Features

* CSRF protection works without additional configuration now.
* Optional deep merging of shared props.

### Fixes

* Document Inertia headers. @buhrmi
* Documentation typo fix. @lujanfernaud
* Changelog URI fix. @PedroAugustoRamalhoDuarte

## [3.0.0] - 2022-09-22

* Allow rails layout to set inertia layout. Thanks @ElMassimo!
* Add the ability to set inertia props and components via rails conventions (see readme)

## [2.0.1] - 2022-07-12

* Fix for a middleware issue where global state could be polluted if an exception occurs in a request. Thanks @ElMassimo!

## [2.0.0] - 2022-06-20

* Fix an issue with Rails 7.0. Thanks @0xDing and @aviemet!
* Drop support for Rails 5.0 (and mentally, though not literally drop support for Rails < 6)

## [1.12.1] - 2022-05-09

* Allow inertia to take over after initial pageload when using ssr. Thanks @99monkey!

## [1.12.0] - 2022-05-04

* SSR!

## [1.11.1] - 2021-06-27

* Fixed thread safety in the middleware. Thanks @caifara!

## [1.11.0] - 2021-03-23

* Fixed the install generator. `installable?` was always returning false, preventing it from actually running.
* Added an install generator for Vue.

## [1.10.0] - 2021-03-22

* Added install generator to quickly add Inertia to existing rails apps via `rails inertia_rails:install:react`

## [1.9.2] - 2021-02-23

* Improve method for detecting whether a user used the RSpec helpers without adding `inertia: true` to the spec
* Emit a warning when expecting an Inertia response in RSpec and never reaching a `render inertia:` call

## [1.9.1] - 2021-02-10

* Define `redirect_to` and `redirect_back` as public methods for compatibility with other code using them

## [1.9.0] - 2021-01-17

* Added the same inertia awareness that redirect_to has to redirect_back

## [1.8.0] - 2020-12-08

* Add `inertia` route helper feature

## [1.7.1] - 2020-11-24

* Fix the definition for InertiaRails::Lazy to avoid an uninitialized constant error when booting an application. 

## [1.7.0] - 2020-11-24

* Add support for "lazy" props while rendering. These are props that never compute on the initial page load. The only render during a partial update that calls for them explicitly.

## [1.6.0] - 2020-11-20

* Built in error sharing across redirects! adding `{ inertia: { errors: 'errors go here' } }` as an option in `redirect_to` will automatically feed an `errors` prop to whatever is rendered after the redirect.
* Set content type to json for Inertia responses
* Return the original response status with Inertia responses

## [1.5.0] - 2020-10-07

* Test against multiple Rails versions in Github Actions
* Add the `inertia_location` controller method that forces a full page refresh

## [1.4.1] - 2020-08-06

* Fixed a bug involving threadsafe versions and layouts

## [1.4.0] - 2020-07-09

* Fixed Ruby 2.7 deprecation warnings
* Added `inertia_partial?` method
* Fixed homepage in the gemspec
* Make the InertiaRails module data threadsafe

## [1.3.1] - 2020-02-20

* Fix a typo in the README (inertia only has 1 t!)

## [1.3.0] - 2020-01-28

### Added

* Added request.inertia? method

## [1.2.2] - 2020-01-21

### Fixed

* Added patches to allow Rails errors to show properly in the inertia modal
* Fixed a middleware issue caused by a breaking change in Rack v2.1.*

## [1.2.1] - 2019-12-6

### Fixed

* Change page url to use path instead of url
* Moved Inertia Share logic to a before_action to ensure it runs on every request

## [1.2.0] - 2019-11-1

### Added

* Added rspec helpers

### Fixed

* Make sure that `inertia_share` properties are reset before each request

## [1.1.0] - 2019-10-24

### Changed

* Switches mattr_accessor defaults to block syntax to allow pre Rails 5.2 compatibility

## [1.0.1] - 2019-10-23

### Fixed

* Allow `Intertia.share` within a controller to access controller methods

## [1.0.0] - 2019-10-09

* Initial release
