# ``Formic``

🐜 Swift library to support IT Automation tasks.  🐜 🐜

## Overview

I'm under no illusion that most any SRE/DevOps people are **not** likely to be interested in this.
As a Swift backed project, so this is for me first and foremost.
If you're stumbled into this, it isn't intended to be a full-bore replacement for any existing tools commonly used for DevOps/SRE/IT Automation.

There's a lot of inspiration from existing IT automation libraries and tools.
Quite a is inspired by [Ansible](https://github.com/ansible/ansible), with a goal of building pre-set sequences of tasks that do useful operational work.

My initial goals are "Day 1" targets (meaning installation and configuration). 
The set of tasks at the moment:

- install all the latest updates for the OS
- install and configure docker
- wrap around 2 or more hosts that have this done and assemble a Docker swarm

I want to be able to use this library to easily create command-line executables that can be run on a remote host.
They would ideally taking a few inputs (as minimal as possible, while still allowing some arguments), and executing a relevant playbook of commands - or resolving state from a declared preset.

## Topics

### Imperative

- ``Playlist``

### Commands

- ``Host``
- ``Command``
- ``CommandOutput``
- ``CommandError``

### Declarative Resources

- ``OperatingSystem``
- ``QueryableState``
