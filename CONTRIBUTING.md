# Contributing to Formic

## Overview

- [issues](https://github.com/heckj/formic/issues) are welcome.
  - this is a personal project and there's no guarantee of support or maintenance.

- [pull requests](https://github.com/heckj/formic/pulls) are welcome.
  - discuss larger features or efforts in an [issue](https://github.com/heckj/formic/issues) first.
  - linting should pass before review.
  - all checks must pass before merging.
  
- Swift 6 language mode
- macOS and Linux support
- [swift-testing](https://developer.apple.com/documentation/testing/)

## Contributing and Support

If this sounds interesting to you - you're welcome to fork/borrow any of this code for your own use (it's intentionally MIT licensed).
I'm also open to contributions, but I'm not looking to build a large community around this.
So pull requests and issues are open and welcome, but I am no beholden to anyone else to fix, change, or resolve issues, and there should be no expectation of support or maintenance.

If you _really_ want to use this, but need some deeper level of support, reach out to me directly, and we can discuss a possible arrangement.

The world of software deployment has changed significantly in the last 20 years, 10 even.
Docker and images, Cloud Functions/Lambdas, Virtual Machines are easily accessible, and a variety of Provider-specific hosted resources from Kubernetes Clusters to CDNs.
There's a lot of places this _could_ go.
If you want to extend and use this as well, please do.

## Tests

As a Swift 6 project, the testing is using [swift-testing](https://developer.apple.com/documentation/testing/) instead of XCTest.

As an IT automation tool, not everything can be easily tested with unit tests.
That said, there's enough abstraction in the API (and I want to keep it so), that this project can leverage the [swift-dependencies](https://github.com/pointfreeco/swift-dependencies)  package to enable a bit of "dependency injection" to make this easier.
There are a couple of internal code structures that are explicitly to support dependency injection. 
Extend the existing ones or add your own as needed to support testing.

The CI system with this package sends coverage data to CodeCov:

[![codecov](https://codecov.io/gh/heckj/formic/graph/badge.svg?token=BGzZDLrdjQ)](https://codecov.io/gh/heckj/formic)

[![code coverag sunburst diagram](https://codecov.io/gh/heckj/formic/graphs/sunburst.svg?token=BGzZDLrdjQ)](https://app.codecov.io/gh/heckj/formic)

## Documentation

As mentioned above, the `.swift-format` configuration is picky about ensuring documentation exists for public types and APIs, and that's verified on continuous integration.
The documentation is hosting courtesy of [Swift Package Index](https://swiftpackageindex.com) - https://swiftpackageindex.com/heckj/formic/documentation/formic

If you're adding, or changing API, in a pull request - make sure to also include any relevant API documentation, and I recommend doing a local build of the documentation to ensure it looks right.


## Style and Formatting

I'm doing this from scratch to do everything in Swift 6 and concurrency safe from the start.
For this project, I'm trying to embrace `swift-format` (the one built-in to the Swift6 toolchain).
There's a script to use pre-push to GitHub (yeah, it could be a git hook):

```bash
./scripts/preflight.bassh
```

It runs the formatter, then the linter - to verify things are "good" locally before pushing to GitHub.
The rules enabled in `.swift-format` in the repository include being pushy and picky about documentation.
For details on the configuration options for `swift-format`, see the  [Configuration documentation](https://github.com/swiftlang/swift-format/blob/main/Documentation/Configuration.md).

If you want to just run the commands on directly:

```bash
swift package lint-source-code
```

```bash
swift package format-source-code --allow-writing-to-package-directory
```

## Checking the code on Linux

The CI system checks this on Linux with Swift 6.
I do development on an Apple Silicon mac, and use Docker (well, Orbstack really) to check on Linux locally as well.

Preload the images:

```bash
docker pull swift:5.9    # 2.55GB
docker pull swift:5.10   # 2.57GB
docker pull swift:6.0    # 3.2GB
```

Get a command-line operational with the version of swift you want. For example:

```bash
docker run --rm --privileged --interactive --tty --volume "$(pwd):/src" --workdir "/src" swift:6.0
```

Append on specific scripts or commands for run-and-done:

```bash
docker run --rm --privileged --interactive --tty --volume "$(pwd):/src" --workdir "/src" swift:6.0 scripts/precheck.bash
```
