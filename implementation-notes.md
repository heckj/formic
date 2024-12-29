## Public API notes/ideas

For a starting point, enable maybe a type that is either an [AsyncParsableCommand](https://swiftpackageindex.com/apple/swift-argument-parser/documentation/argumentparser/asyncparsablecommand) or can be easily consumed within one.

### Playbooks

Structure playbooks **in Swift**, leveraging type safety and structured Resources.

A couple example playbooks:

```swift
let applyUpdates: [(any Command)] = [
    ShellCommand("sudo apt-get update -q"),
    ShellCommand("sudo apt-get upgrade -y"),
])
try await Engine().run(hosts: [hosts...], commands: applyUpdates)
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
        let verbosity: Verbosity = verbose ? .verbose(emoji: true) : .normal(emoji: true)
        try await Engine().run(host: netHost, displayProgress: true, verbosity: verbosity, commands: ]
            ShellCommand("mkdir -p ~/.ssh"),
            ShellCommand("chmod 0700 ~/.ssh"),
            CopyInto(location: privateKeyLocation, from: "~/.ssh/\(keyName)"),
            ShellCommand("chmod 0600 ~/.ssh/\(keyName)"),
        ])
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
let arch = Dpkg.find(host).architecture
Engine().run(hosts: [hosts], commands: [
    DebianPackageDeclaration("docker.io", state: .absent),
    DebianPackageDeclaration("curl", state: .present),
    DebianPackageDeclaration("ca-certificates", state: .present),
    User("docker-user", inGroup: "docker", state: enabled), // alternately: "exists | absent" ?
    Directory("/etc/apt/keyrings", mode: 0755, state: present),
    CopyFrom(location: "/etc/apt/keyrings/docker.asc", from "https://download.docker.com/linux/ubuntu/gpg")
    // install remote apt repo
    // echo \
  // "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  // $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  // sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
    Package("docker-ce", state: .present)
])
```
At the moment, I've nixed an explicit struct to represent a playbook, but I might want to re-introduce 
the concept to allow for dependencies or pre-requisites. The idea being to fail or not allow execution if they're not met - a set of "checks" up front. 
```swift
Require(hostA["OS"] == "Ubuntu")
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

### Resources

Resources being resolved to match declarations should use a 'check' -> 'compute delta' -> 'update' process path

For parsing from remote CLI commands, leverage a regex builder, or [swift-parsing](https://github.com/pointfreeco/swift-parsing), taking a multi-line string (output from well-known CLI tools) and converting that into some structured format.
There are some really interesting examples (in python) in the library [jc](https://github.com/kellyjonbrazil/jc) - used as a plugin parsing tool for Ansible.

### Commands and Responses

`docker node inspect self`

```bash
[]
Status: Error response from daemon: This node is not a swarm manager. Use "docker swarm init" or "docker swarm join" to connect this node to swarm and try again., Code: 1
```

`docker swarm init`

```bash
Swarm initialized: current node (dl490ag3crgutgvzq91id7wo1) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-4co3ccnbcdrww0iq7f9te0478286pd168bhzfx9oyc1wyws0vi-1p35bj1i57s9h9dpf57mmeqq0 198.19.249.61:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

`docker node inspect self` (after init as master)

```bash
[
    {
        "ID": "dl490ag3crgutgvzq91id7wo1",
        "Version": {
            "Index": 9
        },
        "CreatedAt": "2024-12-26T22:21:03.01474325Z",
        "UpdatedAt": "2024-12-26T22:21:03.633315925Z",
        "Spec": {
            "Labels": {},
            "Role": "manager",
            "Availability": "active"
        },
        "Description": {
            "Hostname": "ubuntu",
            "Platform": {
                "Architecture": "aarch64",
                "OS": "linux"
            },
            "Resources": {
                "NanoCPUs": 8000000000,
                "MemoryBytes": 8385671168
            },
            "Engine": {
                "EngineVersion": "27.4.0",
                "Plugins": [
                    {
                        "Type": "Log",
                        "Name": "awslogs"
                    },
                    {
                        "Type": "Log",
                        "Name": "fluentd"
                    },
                    {
                        "Type": "Log",
                        "Name": "gcplogs"
                    },
                    {
                        "Type": "Log",
                        "Name": "gelf"
                    },
                    {
                        "Type": "Log",
                        "Name": "journald"
                    },
                    {
                        "Type": "Log",
                        "Name": "json-file"
                    },
                    {
                        "Type": "Log",
                        "Name": "local"
                    },
                    {
                        "Type": "Log",
                        "Name": "splunk"
                    },
                    {
                        "Type": "Log",
                        "Name": "syslog"
                    },
                    {
                        "Type": "Network",
                        "Name": "bridge"
                    },
                    {
                        "Type": "Network",
                        "Name": "host"
                    },
                    {
                        "Type": "Network",
                        "Name": "ipvlan"
                    },
                    {
                        "Type": "Network",
                        "Name": "macvlan"
                    },
                    {
                        "Type": "Network",
                        "Name": "null"
                    },
                    {
                        "Type": "Network",
                        "Name": "overlay"
                    },
                    {
                        "Type": "Volume",
                        "Name": "local"
                    }
                ]
            },
            "TLSInfo": {
                "TrustRoot": "-----BEGIN CERTIFICATE-----\nMIIBajCCARCgAwIBAgIUO9OOMGvhY64AA2kw/lfXryEFuXkwCgYIKoZIzj0EAwIw\nEzERMA8GA1UEAxMIc3dhcm0tY2EwHhcNMjQxMjI2MjIxNjAwWhcNNDQxMjIxMjIx\nNjAwWjATMREwDwYDVQQDEwhzd2FybS1jYTBZMBMGByqGSM49AgEGCCqGSM49AwEH\nA0IABC7+2PH44yM5SJzGpTc8vwC7UbEATq3X3J3vA3wWb85B6/uTBD0+Q62R/M7m\nUM7moPiS/0uG/t2pH9vcyCfdBcqjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMB\nAf8EBTADAQH/MB0GA1UdDgQWBBRIZCf19lGPvLmd+Fpgn9HhT5DjYTAKBggqhkjO\nPQQDAgNIADBFAiEAmCO5hmq2R7Wr+bWw9oD1T36S8DqGV8/7OEr8Cy1qFb0CIDR3\nM3VPEgX3b8fCwGTHW18XZQ5bt/7yYUnSF71JcIKC\n-----END CERTIFICATE-----\n",
                "CertIssuerSubject": "MBMxETAPBgNVBAMTCHN3YXJtLWNh",
                "CertIssuerPublicKey": "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAELv7Y8fjjIzlInMalNzy/ALtRsQBOrdfcne8DfBZvzkHr+5MEPT5DrZH8zuZQzuag+JL/S4b+3akf29zIJ90Fyg=="
            }
        },
        "Status": {
            "State": "ready",
            "Addr": "198.19.249.61"
        },
        "ManagerStatus": {
            "Leader": true,
            "Reachability": "reachable",
            "Addr": "198.19.249.61:2377"
        }
    }
]
```

```bash
docker-user@ubuntu:~$ docker node ls
ID                            HOSTNAME   STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
dl490ag3crgutgvzq91id7wo1 *   ubuntu     Ready     Active         Leader           27.4.0
```

```bash
docker-user@ubuntu:~$ docker swarm join-token worker
To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-4co3ccnbcdrww0iq7f9te0478286pd168bhzfx9oyc1wyws0vi-1p35bj1i57s9h9dpf57mmeqq0 198.19.249.61:2377
```
