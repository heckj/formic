# Formic 🐜

Swift library to support IT Automation tasks.

I'm under no illusion that most any SRE/DevOps people are likely to be interested in doing this sort of development in Swift, so this is for me first and foremost.
As such, this isn't intended to be a full-bore replacement for any existing tools commonly used for DevOps/SRE/IT Automation.

## Goals/Focus

There's a lot of inspiration from existing IT automation libraries and tools.
A lot of the basic intuition and initial structure comes from Ansible, with a goal of building pre-set sequences of tasks that do something.
My initial goal is to assemble enough of this to enable the classic "Day 1" things for my own projects.

My initial goals Day 1 goal targets are:

- install all the latest updates for the OS
- install and configure docker
- wrap around 2 or more hosts that have this done and assemble a Docker swarm

As I'm starting this, I'm using a local [punchlist](./punchlist.md) to keep track of what I'm working on.
Down the road, I'll switch to GitHub issues.

### How/Loose Structure

I want to do this with a declarative structure that has an idea of state, using the "Operator" pattern to inspect current state and then resolve to the desired endpoint.
I'd like to have the idea of multiple levels of verification for these declared resources. Right now I'm thinking of these as "diagnostic levels" (yeah, totally riffing on SciFi themes here).
1. verifying they're there at all.
2. inspecting their outputs or ancillary systems to verify they seem to be working.
3. interaction with the service in a sort of "smoke test" - verifying simple functionality.
4. ... way more fuzzy here - but a realm of possible extensions that work to characterize the service - performance, SLA measurements, or end to end tests and validation akin to "acceptance tests".

There's a TON of detail that could be modeled and explored with the Software Configuration space.
This is my own exploration of it, for my services and projects.
I'm not trying to model the whole system, or all the details.
Right now I'm leaning towards only modeling aspects from OS that are bits that the systems I want to use depend upon.

The world of software deployment has changed significantly in the last 20 years, 10 even.
Docker and images, Cloud Functions/Lambdas, Virtual Machines easily accessible, and a variety of Provider-specific hosted resources from Kubernetes Clusters to CDNs.

For the world of VMs, like Ansible, I'm aiming for agent-less operation, following the same loose pattern of "accessing over SSH".
As such, there'll need to be code to parse CLI tooling output and wrangle it into a more structured format, with an idea to derive subsidiary resources and their state from those tools.

### What it isn't

Right now, this is intended to be "run a CLI tool once" and it does a single pass (also like Ansible), running whatever playbooks or resolving the declared structures that are provided.
There's a follow on step that moves more towards the "Operator" pattern (borrowing from CoreOS and Kubernetes) that can remain active, watches the system, and resolves drift from the desired state.
This isn't the immediate goal, but I want to be aware of that as a possible future goal, not cutting off API or structures that could be used in that context.

## Contributing and Support

If this sounds interesting to you - you're welcome to fork/borrow any of this code for your own use (it's intentionally MIT licensed).
I'm also open to contributions, but I'm not looking to build a large community around this.
So pull requests and issues are open and welcome, but I am no beholden to anyone else to fix, change, or resolve issues, and there should be no expectation of support or maintenance.

If you _really_ want to use this, but need some deeper level of support, please reach out to me directly, and we can discuss an possible arrangement.

## Experiment

There's a script to use pre-push to GitHub (yeah, it maybe should be a hook):

```bash
./scripts/precheck.bassh
```

It runs the formatter, linter, and then tests - to verify things are "good" locally before pushing to GitHub.

For this project, I'm trying to embrace `swift-format` (the one built-in to the Swift6 toolchain).
The package has a dependency on `swift-format`, so the following package plugin commands are available:

```bash
swift package lint-source-code
```

```bash
swift package format-source-code --allow-writing-to-package-directory
```

swift-format uses the built-in default style to lint and format code.
A `.swift-format` configuration file can be used to customize the style used.
See [Configuration](https://github.com/swiftlang/swift-format/blob/main/Documentation/Configuration.md) for more details on customization options.

### Checking on Linux

(Uses Docker or Orbstack)

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
