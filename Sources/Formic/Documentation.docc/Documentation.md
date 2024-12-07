# ``Formic``

🐜 Swift library to support IT Automation tasks.  🐜 🐜

## Overview

This is a library to support building IT automation tools in Swift, taking a lot of inspiration from existing and past IT automation tools.
It is not a replacement for Ansible, Terraform, Chef, etc, but operates in a similar way to support building your own focused CLI tools.
I expect that most SRE/DevOps staff are not going to be interested in creating something using the Swift language.
Instead, this library is intended to support building CLI executables with swift-argument-parser, or other dedicated tooling for managing remote system.
If you've just stumbled over this project, it isn't intended to be a full-bore replacement for any existing tools commonly used for DevOps/SRE/IT Automation.

There's a lot of inspiration from existing IT automation libraries and tools.
Quite a is inspired by [Ansible](https://github.com/ansible/ansible), with a goal of building pre-set sequences of tasks that do useful operational work.

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
