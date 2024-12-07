## Public API notes/ideas

For a starting point, enable maybe a type that is either an [AsyncParsableCommand](https://swiftpackageindex.com/apple/swift-argument-parser/documentation/argumentparser/asyncparsablecommand) or can be easily consumed within one.

### Playbooks

Structure playbooks **in Swift**, leveraging type safety and structured Resources.

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

### Resources

Resources being resolved to match declarations should use a 'check' -> 'compute delta' -> 'update' process path

For parsing from remote CLI commands, leverage a regex builder, or [swift-parsing](https://github.com/pointfreeco/swift-parsing), taking a multi-line string (output from well-known CLI tools) and converting that into some structured format.
There are some really interesting examples (in python) in the library [jc](https://github.com/kellyjonbrazil/jc) - used as a plugin parsing tool for Ansible.

