## Public API notes/ideas

For a starting point, enable maybe a type that is either an [AsyncParsableCommand](https://swiftpackageindex.com/apple/swift-argument-parser/documentation/argumentparser/asyncparsablecommand) or can be easily consumed within one.

### Playbooks

Structure playbooks **in Swift**, leveraging type safety and structured Resources.

A couple example playbooks:

```swift
let createDockerHost = Playbook(name: "apply pending upgrades", hosts: hosts, commands: [
    ShellCommand("sudo apt-get update -q"),
    ShellCommand("sudo apt-get upgrade -y"),
])
```

```swift
import Foundation
import ArgumentParser
import Formic
typealias Host = Formic.Host

@main
struct configureBastion: AsyncParsableCommand {
    @Argument(help: "The network address of the host to update") var netAddress: Host.NetworkAddress
    @Option(name: .shortAndLong, help: "The user to connect as") var user: String = "docker-user"
    @Option(name: .shortAndLong, help: "The port to connect through") var port: Int = 22  // default ssh port
    @Option(name: .long, help: "The identity file to use") var identityFile: String? = nil

    @Argument(help: "The path to the private SSH key to copy") var privateKeyLocation: String

    @Flag(name: .shortAndLong, help: "Run in verbose mode") var verbose: Bool = false

    mutating func run() async throws {
        let keyName = URL(fileURLWithPath: privateKeyLocation).lastPathComponent
        let netHost: Host = try Host(netAddress, sshPort: port, sshUser: user, sshIdentityFile: identityFile)
        let setupSSHKey = Playbook(name: "install SSH private key", hosts: [netHost], commands: [
            ShellCommand("mkdir -p ~/.ssh"),
            ShellCommand("chmod 0700 ~/.ssh"),
            CopyInto(location: privateKeyLocation, from: "~/.ssh/\(keyName)"),
            ShellCommand("chmod 0600 ~/.ssh/\(keyName)"),
        ])
        let verbosity: Verbosity = verbose ? .verbose(emoji: true) : .normal(emoji: true)
        try await Engine().run(playbook: setupSSHKey, displayProgress: true, verbosity: verbosity)
    }
}
```

Host -> RemoteHost?, OS?, NetHost? - host seems overloaded, as well as a type already in Foundation, which is causing some confusion. Just NetworkAddress?
I need this for ShellCommand in particular, but otherwise it's really about the network address to uniquely
identify the location to work with.

ShellCommand() -> SHCmd(), Cmd() // for brevity?

### Resources

ideas for what declarative versions might look like:

```swift
let packages = DebianPackage.query(host)
let packages = DebianPackage.find(host)
apply { host in
    Package("docker.io", state: absent)
    Package("curl", state: present)
    Package("ca-certificates", state: present)  // alternately: "installed | removed" ?
    User("docker-user", inGroup: "docker", state: enabled) // alternately: "exists | absent" ?
    Directory("/etc/apt/keyrings", mode: 0755, state: present)
    CopyFrom(location: "/etc/apt/keyrings/docker.asc", from "https://download.docker.com/linux/ubuntu/gpg")
    let arch = DebianPackage(host).architecture
    
    // install remote apt repo
    // echo \
  // "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  // $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  // sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
    Package("docker-ce", installed: true)
    
    let envset = ENVSET("/etc/os-release")
}
```
```bash
docker-user@ubuntu:~$ cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.1 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.1 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo

docker-user@ubuntu:~$ cat /etc/lsb-release
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=24.04
DISTRIB_CODENAME=noble
DISTRIB_DESCRIPTION="Ubuntu 24.04.1 LTS"
```


```swift
struct MyPlaylist: AsyncParsableCommand {
  @Argument host: String
  @Option user: String?
  ...
  func run() async {
    let myHost = Host(ip: host)
    myHost.apply() {
      allAvailableUpdatesInstalled(securityOnly: true)
      DockerNode(state: enabled, service: active, forUser: user)
    }
  }
}
```

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

### Resources

Resources being resolved to match declarations should use a 'check' -> 'compute delta' -> 'update' process path

For parsing from remote CLI commands, leverage a regex builder, or [swift-parsing](https://github.com/pointfreeco/swift-parsing), taking a multi-line string (output from well-known CLI tools) and converting that into some structured format.
There are some really interesting examples (in python) in the library [jc](https://github.com/kellyjonbrazil/jc) - used as a plugin parsing tool for Ansible.

