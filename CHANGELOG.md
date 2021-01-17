# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
