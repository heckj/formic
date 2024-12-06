# Punchlist

- [x] try out Dependency from PointFree for testing
- [x] try out SwiftCommand instead of my quick-hack over Process (async processes)
- [ ] rough out the architecture and usage
  - [ ] figure out arguments and options w/ swift-arg-parser
  - [x] flesh out Queryable for returning/updating resource types (all resources w/ state should be Queryable)
  - [ ] make a Resource protocol that extends to Codable as well
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
