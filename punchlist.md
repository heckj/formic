# Punchlist

- [ ] rough out the architecture and usage
  - [x] figure out arguments and options w/ swift-arg-parser
  - [x] flesh out Queryable for returning/updating resource types (all resources w/ state should be Queryable)
  - [ ] make a Resource protocol that extends to Codable as well
    - [x] make IPv4Address codable (tuples!)
  - [ ] work out what "Resolvable" protocol might look like - sequence of commands to go from one state to a desired
        end state.
  - [x] idea of "Resource" with state - protocol and/or structure?
  - [x] idea of Hosts that reflect Operating Systems running somewhere, with things to configure on them.
  - [x] declaration structure for Command
- [x] Playlist (struct of commands invoked in sequence)
- [ ] add some Dependency injection support while using the DNS resolver to speed up the base line tests
- [ ] Resources
  - [ ] OperatingSystem
  - [ ] Packages
  - [ ] Users/Groups
- [ ] create the JSON/structs to decode the Terraform state dump data to use as input for the tooling
- [x] write up CONTRIBUTING.md
