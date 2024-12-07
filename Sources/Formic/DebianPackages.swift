import Foundation
import Parsing

// An example resource
// - a collection of debian packages
// - declared state of installed vs. not

// Resource pieces and operating on them:

// 0 - persist-able and comparable
//    - `Codable`, `Hashable`
//
// 1 - a declarative structure to represent what we want it to be
//    - ??
//
// 2 - a way query the current state - "QueryableState"
//    - `shellcommand`, `parse(_ output: String) -> Self`, used by
//      `queryState(from host: Host) throws -> (Self, Date)`
//    - should I differentiate between "checking this specific one" and "checking all"?
//
// 3 - a way to compute the changes needed to get into that desired state
//    - knowledge of (1), and `resolve()`
//
// 4 - the actions to take to make those changes
//
// 5 - a way to test the state of the resource (various diagnostic levels?)

/// The kind of operating system.
public struct DebianPackage: QueryableState {
    public static let shellcommand: Command = .shell("dpkg", "-l")

    // borrow from https://github.com/kellyjonbrazil/jc
    // MIT License: https://github.com/kellyjonbrazil/jc/blob/master/LICENSE.md
    // - https://github.com/kellyjonbrazil/jc/blob/master/jc/parsers/dpkg_l.py
    // - https://github.com/kellyjonbrazil/jc/blob/master/docs/parsers/dpkg_l.md

    public static func parse(_ output: String) throws -> DebianPackage {
        fatalError("not implemented")
    }

}
