# Changelog
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [0.5.1] - 2015-12-03
### Changed
- Make some fragment-related functions private

### Deprecate
- Deprecate fragment definition use of `fragment()`: use `def_fragment()` for
  that instead

### Added
- Add `def_fragment()` replacement for overloaded fragment-definition use of
  `fragment()`
- Better API doc and examples for intrinsic functions
- API doc and examples for fragments

## [0.5.0] - 2015-12-03
Yanked - implemented 0.5.1's changes in a breaking way rather than deprecating

## [0.4.0] - 2015-06-10
### Added
- Add example to README
- Add command-line runner
- Add Rake task class

## [0.3.0] - 2015-05-27
### Added
- Initial public release covering all the basics (missing a couple of intrinsic
  functions)
