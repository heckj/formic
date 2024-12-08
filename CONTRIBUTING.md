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

If you _really_ want to use this, but need some deeper level of support, please reach out to me directly, and we can discuss an possible arrangement.

The world of software deployment has changed significantly in the last 20 years, 10 even.
Docker and images, Cloud Functions/Lambdas, Virtual Machines are easily accessible, and a variety of Provider-specific hosted resources from Kubernetes Clusters to CDNs.
There's a lot of places this _could_ go.
If you want to extend and use this as well, please do.

## Project Goals

There's a huge amount of inspiration from my own use of IT automation tools, from Ansible, Puppet, Chef, Terraform, and the lessons learned managing systems over the years.

The primary goal of this project is to provide support for building command-line executable tools that have the same feeling as assembling playlists in Ansible.
The starting point are imperative actions that are easily assembled, all invoked remotely, primarily using SSH as a transport.
Extending from that, API for a declarative that uses the basic "operator" pattern for inspecting current state, computing the delta, and invoking actions to change it to the desired state.

- Swift 6 language mode (full concurrency safety)
- macOS and Linux support

### Loose Architecture / Structure

I want to do this with a declarative structure that has an idea of state, using a single-pass following the operator pattern:

- start with a declared state
- inspect current state
- compute the delta
- invoke actions to resolve the delta

To use a declarative structure, there needs to be an API structure that holds the state - what I'm currently calling a Resource.
A Resource doesn't need to model everything on a remote system, only the pieces that are relevant to the tasks at hand.

In addition to inspecting state, I want to extend Resource to include some actions to allow deeper inspection, with multiple levels of verification.
I'm calling these "diagnostic levels" (borrowing from SciFi themes).

1. verifying they're there at all.
2. inspecting their outputs or ancillary systems to verify they seem to be working.
3. interaction with the service in a sort of "smoke test" - verifying simple functionality.
4. ... way more fuzzy here - but a realm of possible extensions that work to characterize the service - performance, SLA measurements, or end to end tests and validation akin to "acceptance tests".

I'd like the idea of a resource to be flexible enough to represent a singular process or service, or even just a configuration file, through to a set of services working in coordination across a number of hosts. 

### What this isn't

This isn't meant to be a general parser for text structures or support an extension external DSL (what Ansible, Puppet, Chef, or Terraform have done). It is meant for swift developers to be able to assemble and build their own devops tools, particularly dedicated CLI tools leveraging [swift-argument-parser](https://swiftpackageindex.com/apple/swift-argument-parser/documentation/argumentparser).

### Forward Looking

The public API is focused on building "run a CLI tool once", performing a single pass to run any imperative efforts, or resolve declarative state (when that's added) - very akin to what Ansible does.

Down the road, I'd like to consider moving more towards the ["Operator" pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/), and extending API to support that use case. 
That entails enabling the API to be used to build custom operators (borrowing from CoreOS and Kubernetes) that can remain active, watches the system, and resolves drift from the desired state.
This isn't the immediate goal, but I want to be aware of that as a possible future goal, not cutting off API or structures that could be used in that context.

## Tests

As a Swift 6 project, the testing is using [swift-testing](https://developer.apple.com/documentation/testing/) instead of XCTest.

As an IT automation tool, not everything can be easily tested with unit tests.
That said, there's enough abstraction in the API (and I want to keep it so), that this project can leverage the [swift-dependencies](https://github.com/pointfreeco/swift-dependencies)  package to enable a bit of "dependency injection" to make this easier.
There are a couple of internal code structures that are explicitly to support dependency injection. 
Extend the existing ones or add your own as needed to support testing.

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
