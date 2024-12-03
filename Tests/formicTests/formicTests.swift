import Testing

@testable import Formic

@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    
    let sample = "192.176.3.17"
    let another = /^(?:(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])(\.(?!$)|$)){4}$/
//     let another = /^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$/

    let result = try another.wholeMatch(in: sample)
    print("result is \(String(describing: result?.output))")
}
