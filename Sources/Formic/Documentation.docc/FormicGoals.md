# Package Goals and Architecture

An overview of how and why this package exists, and what it's intended to do.

## Overview

There's a huge amount of inspiration from my own use of IT automation tools, from Ansible, Puppet, Chef, Terraform, and the lessons learned managing systems over the years.

The primary goal of this project is to provide support for building command-line executable tools that have the same feeling as assembling playlists in Ansible.
The starting point are imperative actions that are easily assembled, all invoked remotely, primarily using SSH as a transport.
Extending from that, API for a declarative that uses the basic "operator" pattern for inspecting current state, computing the delta, and invoking actions to change it to the desired state.

- Swift 6 language mode (full concurrency safety)
- macOS and Linux support

### High Level Architecture

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

### Future Directions

The public API is focused on building "run a CLI tool once", performing a single pass to run any imperative efforts, or resolve declarative state (when that's added) - very akin to what Ansible does.

Down the road, I'd like to consider moving more towards the ["Operator" pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/), and extending API to support that use case. 
That entails enabling the API to be used to build custom operators (borrowing from CoreOS and Kubernetes) that can remain active, watches the system, and resolves drift from the desired state.
This isn't the immediate goal, but I want to be aware of that as a possible future goal, not cutting off API or structures that could be used in that context.
