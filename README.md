# Formic 🐜

Swift library to support IT Automation tasks.

## Overview

This is a library to support building IT automation tools in Swift, taking a lot of inspiration from existing and past IT automation tools.
It's meant to operate similarly to Ansible, focusing on configuring the software on remote hosts using a channel of "ssh" to those hosts, presumably with a key you already have.

I expect that most SRE/DevOps staff are not going to be interested in creating something using the Swift language.
Instead, I'm assembling these pieces to support building my own custom playbooks and tools for managing remote hosts and services.

- [API Documentation](https://swiftpackageindex.com/heckj/formic/main/documentation/formic)

I've included a hard-coded example of using this library from an argument-parser based CLI tool.
Look through the content in [updateExample](examples/updateExample) to get a sense of using it in practice.
