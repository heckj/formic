import Foundation
import Testing

@testable import Formic

@Test("verify backoff logic - .none")
func testBackoffDelayLogicNone() async throws {
    let strategy = Backoff.Strategy.none
    #expect(strategy.delay(for: 0) == 0)
    #expect(strategy.delay(for: 10) == 0)
}

@Test("verify backoff logic - .constant")
func testBackoffDelayLogicConstant() async throws {
    let strategy = Backoff.Strategy.constant(delay: 3.5)
    #expect(strategy.delay(for: 0) == 3.5)
    #expect(strategy.delay(for: 10) == 3.5)
}

@Test("verify backoff logic - .linear")
func testBackoffDelayLogicLinear() async throws {
    let strategy = Backoff.Strategy.linear(increment: 2, maxDelay: 3.5)
    #expect(strategy.delay(for: 0) == 0)
    #expect(strategy.delay(for: 1) == 2)
    #expect(strategy.delay(for: 10) == 3.5)
}

@Test("verify backoff logic - .fibonacci")
func testBackoffDelayLogicFibonacci() async throws {
    let strategy = Backoff.Strategy.fibonacci(maxDelay: 3.5)
    #expect(strategy.delay(for: 0) == 0)
    #expect(strategy.delay(for: 1) == 1)
    #expect(strategy.delay(for: 2) == 1)
    #expect(strategy.delay(for: 3) == 2)
    #expect(strategy.delay(for: 4) == 3)
    #expect(strategy.delay(for: 10) == 3.5)
}

@Test("verify backoff logic - .exponential")
func testBackoffDelayLogicExponential() async throws {
    let strategy = Backoff.Strategy.exponential(maxDelay: 3.5)
    #expect(strategy.delay(for: 0) == 0)
    #expect(strategy.delay(for: 1) == 1)
    #expect(strategy.delay(for: 2) == 2)
    #expect(strategy.delay(for: 3) == 3.5)
    #expect(strategy.delay(for: 4) == 3.5)
    #expect(strategy.delay(for: 10) == 3.5)
}
