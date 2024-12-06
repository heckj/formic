# ``Formic``

🐜 Swift library to support IT Automation tasks.  🐜 🐜

## Overview

I'm under no illusion that most any SRE/DevOps people are likely to be interested in doing this sort of development in Swift, so this is for me first and foremost.
As such, this isn't intended to be a full-bore replacement for any existing tools commonly used for DevOps/SRE/IT Automation.

There's a lot of inspiration from existing IT automation libraries and tools.
A lot of the basic intuition and initial structure comes from Ansible, with a goal of building pre-set sequences of tasks that do something.
My initial goal is to assemble enough of this to enable the classic "Day 1" things for my own projects.

My initial goals Day 1 goal targets are:

- install all the latest updates for the OS
- install and configure docker
- wrap around 2 or more hosts that have this done and assemble a Docker swarm

I want to be able to use this library to easily create command-line executables that can be run on a remote host, taking a few inputs (as minimal as possible, while still allowing some arguments), and executing a relevant playbook - or resolving state from a declared preset.

## Topics

### Imperative

- ``Playlist``

### Commands

- ``Command``
- ``CommandOutput``
- ``CommandError``

### Hosts

- ``Host``
- ``NetworkAddress``
- ``IPv4Address``
- ``SSHAccessCredentials``

### Declarative Resources

- ``OperatingSystem``
- ``QueryableState``
