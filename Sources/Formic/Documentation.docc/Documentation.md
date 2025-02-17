# ``Formic``

🐜 Swift library to support IT Automation tasks.  🐜 🐜

## Overview

This is a library to support building IT automation tools in Swift, taking a lot of inspiration from existing and past IT automation tools.
This library is intended to support building CLI executables with swift-argument-parser, or other dedicated tooling for managing remote system.
If you've just stumbled into this project, it isn't intended to be a full-bore replacement for any existing tools commonly used for DevOps/SRE/IT Automation.
Quite a bit is inspired by [Ansible](https://github.com/ansible/ansible), with a goal of building pre-set sequences of tasks that do useful operational work.
For more information on the project, see <doc:FormicGoals>. 

To use formic, create an instance of `Engine`, handing it a configured logger if you want to see informational or detailed about while commands are executed, and use ``Engine/run(host:displayProgress:verbosity:commands:)`` or ``Engine/run(hosts:displayProgress:verbosity:commands:)`` to run commands on those hosts.
Formic works with the idea of running a set of commands against a single host, or all of those same commands against a set of hosts.
A ``Host`` in formic holds the collection of network address as well as credentials needed to access the host.

```swift
var logger = Logger(label: "updateExample")
logger.logLevel = .info 
// use `.trace` for detailed output of raw commands invoked as well 
// as the standard output and standard error returned from commands.

let engine = Engine(logger: logger)

guard let hostAddress = Host.NetworkAddress(hostname) else {
    fatalError("Unable to parse the provided host address: \(hostname)")
}
let targetHost: Host = try Host(hostAddress, 
                                sshPort: port, 
                                sshUser: user, 
                                sshIdentityFile: privateKeyLocation)

// environment variables to use while invoking commands on the remote host
let debUnattended = ["DEBIAN_FRONTEND": "noninteractive", 
                     "DEBCONF_NONINTERACTIVE_SEEN": "true"]

try await engine.run(
    host: targetHost, displayProgress: true, verbosity: verbosity,
    commands: [
        // Apply all current upgrades available
        ShellCommand("sudo apt-get update -q", env: debUnattended),
        ShellCommand("sudo apt-get upgrade -y -qq", env: debUnattended),
    ])
```

For a more fleshed out example, review the example source for the [updateExample CLI executable](https://github.com/heckj/formic/blob/main/examples/updateExample/Sources/updateExample.swift).

## Topics

### Running Playbooks

- ``Engine``
- ``CommandExecutionResult``
- ``Verbosity``

### Commands

- ``Host``
- ``Command``
- ``CommandOutput``
- ``CommandError``

### Built-in Commands

- ``ShellCommand``
- ``SSHCommand``
- ``CopyFrom``
- ``CopyInto``
- ``AnyCommand``
- ``VerifyAccess``

### Resources

- ``OperatingSystem``
- ``Dpkg``

- ``Resource``
- ``ParsedResource``
- ``StatefulResource``
- ``ResourceError``

### Resource Parsers

- ``SwarmJoinCommand``

### Singular Resources

- ``SingularResource``

### Collections of Resources

- ``CollectionResource``

### About Formic

- <doc:FormicGoals>

