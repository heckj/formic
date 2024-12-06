# Punchlist

- [x] try out Dependency from PointFree for testing
- [x] try out SwiftCommand instead of my quick-hack over Process (async processes)
- [ ] rough out the architecture and usage
  - [x] figure out arguments and options w/ swift-arg-parser
  - [x] flesh out Queryable for returning/updating resource types (all resources w/ state should be Queryable)
  - [ ] make a Resource protocol that extends to Codable as well
    - [ ] make IPv4Address codable (tuples!)
  - [ ] work out what "Resolvable" protocol might look like - sequence of commands to go from one state to a desired
        end state.
  - [x] idea of "Resource" with state - protocol and/or structure?
  - [x] idea of Hosts that reflect Operating Systems running somewhere, with things to configure on them.
  - [x] declaration structure for Command
- [ ] Playlist (struct of commands invoked in sequence)
- [ ] Resources
  - [ ] OperatingSystem
  - [ ] Packages
  - [ ] Users/Groups
- [ ] create the JSON/structs to decode the Terraform state dump data to use as input for the tooling
- [ ] write up CONTRIBUTING.md

## Public API notes/ideas

No, I haven't thought this through completely, but it's a starting point.

At a high level, I want to enable maybe a type that is either an [AsyncParsableCommand](https://swiftpackageindex.com/apple/swift-argument-parser/1.5.0/documentation/argumentparser/asyncparsablecommand) or can be easily invoked from within one. 
- could make a top-level command your overall playbook, and have additive elements that invoke playbooks with subcommands if that's useful? (https://swiftpackageindex.com/apple/swift-argument-parser/1.5.0/documentation/argumentparser/commandsandsubcommands)

an example declarative playlist:

```swift
struct MyPlaylist: AsyncParsableCommand {
  @Argument host: String
  @Option user: String?
  ...
  func run() async {
    let myHost = Host(ip: host)
    myHost.apply() {
      allAvailableUpdatesInstalled(securityOnly: true)
      Docker(state: installed, service: active, forUser: user)
    }
  }
}
```

another declarative playlist w/ a structure that requires multiple hosts:

```swift
struct MyPlaylist: AsyncCommand {
  @Argument host: [String]
  @Option user: String?
  ...
  func run() async {
    let master = host[0]
    let workers = host[1...]
    DockerSwarm(masterNode: master, 
                workerNodes: workers, 
                state: active)
    
  }
}
```

an example imperative playlist:

```swift
struct BackupDatabase: AsyncCommand {
  @Option db: String
  @Option user: String
  @Option passwd: String
  ...
  func run() async {
    let dbInstance = DB(ip: host)
    Playlist(dbInstance) {
      let localBackupFile = await DatabaseBackup(host: db, user: user, password: passwd)
      S3Bucket.push(localBackupFile, toBucket: stringOfBucket)
      Discord.notify("Successful backup!")
    }
  }
}
```

- maybe set up something like Host() to conform to ExpressibleByArgument https://swiftpackageindex.com/apple/swift-argument-parser/1.5.0/documentation/argumentparser/expressiblebyargument
    - baseline - IPv4
    - possible DNS, IPv6_address

### Types

**Host**
- address/hostname
- userid
- ssh-identity-file (key)
- ssh-port
- state
    - accessible
    - pingable

**IPv4**
(IPv6?)

**Playlist** (imperative)
**HostResource** protocol (supporting declarative state) ?
    - state
    - stateType
    - refresh rate
- **OS**(dpkg, updates, services, package-updates, users+groups, authorized_keys, sudoers, file)
- +(Docker, nginx, redis)

- **ClusterResource** (declarative that uses multiple hosts) ?
- **DockerSwarm**

Resources being resolved to match declarations should use a 'check' -> 'compute delta' -> 'update' process path

Imperative structures and setup

- **Command** (uses invoke -> output)
    - name
    - capture_output: Bool
    - outputParser ?

**PlayList**: [any Command]
- invoke()
- status
- error_messages: [String]



