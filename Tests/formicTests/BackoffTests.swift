import Foundation
import Testing

@testable import Formic

@Test("verify backoff logic - .none")
func testBackoffDelayLogicNone() async throws {
    let strategy = Backoff.Strategy.none
    #expect(strategy.delay(for: 0) == .seconds(0))
    #expect(strategy.delay(for: 10) == .seconds(0))
}

@Test("verify backoff logic - .constant")
func testBackoffDelayLogicConstant() async throws {
    let strategy = Backoff.Strategy.constant(delay: .seconds(3.5))
    #expect(strategy.delay(for: 0) == .seconds(3.5))
    #expect(strategy.delay(for: 10) == .seconds(3.5))
}

@Test("verify backoff logic - .linear")
func testBackoffDelayLogicLinear() async throws {
    let strategy = Backoff.Strategy.linear(increment: .seconds(2), maxDelay: .seconds(3.5))
    #expect(strategy.delay(for: 0) == .seconds(0))
    #expect(strategy.delay(for: 1) == .seconds(2))
    #expect(strategy.delay(for: 10) == .seconds(3.5))
}

@Test("verify backoff logic - .fibonacci")
func testBackoffDelayLogicFibonacci() async throws {
    let strategy = Backoff.Strategy.fibonacci(maxDelay: .seconds(3.5))
    #expect(strategy.delay(for: 0) == .seconds(0))
    #expect(strategy.delay(for: 1) == .seconds(1))
    #expect(strategy.delay(for: 2) == .seconds(1))
    #expect(strategy.delay(for: 3) == .seconds(2))
    #expect(strategy.delay(for: 4) == .seconds(3))
    #expect(strategy.delay(for: 10) == .seconds(3.5))
}

@Test("verify backoff logic - .exponential")
func testBackoffDelayLogicExponential() async throws {
    let strategy = Backoff.Strategy.exponential(maxDelay: .seconds(3.5))
    #expect(strategy.delay(for: 0) == .seconds(0))
    #expect(strategy.delay(for: 1) == .seconds(1))
    #expect(strategy.delay(for: 2) == .seconds(2))
    #expect(strategy.delay(for: 3) == .seconds(3.5))
    #expect(strategy.delay(for: 4) == .seconds(3.5))
    #expect(strategy.delay(for: 10) == .seconds(3.5))
}
