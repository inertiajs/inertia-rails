# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
