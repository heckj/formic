import Foundation
import Testing

@testable import Formic

@Test("verify backoff logic - .none")
func testBackoffDelayLogicNone() async throws {
    let strategy = Backoff.Strategy.none
    #expect(strategy.delay(for: 0, withJitter: false) == .seconds(0))
    #expect(strategy.delay(for: 10, withJitter: false) == .seconds(0))
}

@Test("verify backoff builtins")
func testBackoffBuiltings() async throws {
    let backoff = Backoff.never
    #expect(backoff.maxRetries == 0)
    #expect(backoff.strategy == .none)

    let backoff2 = Backoff.default
    #expect(backoff2.maxRetries == 3)
    #expect(backoff2.strategy == .fibonacci(maxDelay: .seconds(10)))
}

@Test("verify backoff initializer with negative value")
func testBackoffDelayInitnegative() async throws {
    let negBackoff = Backoff(maxRetries: -1, strategy: .none)
    #expect(negBackoff.maxRetries == 0)
}

@Test("verify backoff logic - .constant")
func testBackoffDelayLogicConstant() async throws {
    let strategy = Backoff.Strategy.constant(delay: .seconds(3.5))
    #expect(strategy.delay(for: 0, withJitter: false) == .seconds(3.5))
    #expect(strategy.delay(for: 10, withJitter: false) == .seconds(3.5))
}

@Test("verify backoff logic - .linear")
func testBackoffDelayLogicLinear() async throws {
    let strategy = Backoff.Strategy.linear(increment: .seconds(2), maxDelay: .seconds(3.5))
    #expect(strategy.delay(for: 0, withJitter: false) == .seconds(0))
    #expect(strategy.delay(for: 1, withJitter: false) == .seconds(2))
    #expect(strategy.delay(for: 10, withJitter: false) == .seconds(3.5))

    #expect(strategy.delay(for: 1, withJitter: true) != .seconds(2))
}

@Test("verify backoff logic - .fibonacci")
func testBackoffDelayLogicFibonacci() async throws {
    let strategy = Backoff.Strategy.fibonacci(maxDelay: .seconds(3.5))
    #expect(strategy.delay(for: 0, withJitter: false) == .seconds(0))
    #expect(strategy.delay(for: 1, withJitter: false) == .seconds(1))
    #expect(strategy.delay(for: 2, withJitter: false) == .seconds(1))
    #expect(strategy.delay(for: 3, withJitter: false) == .seconds(2))
    #expect(strategy.delay(for: 4, withJitter: false) == .seconds(3))
    #expect(strategy.delay(for: 10, withJitter: false) == .seconds(3.5))

    #expect(strategy.delay(for: 3, withJitter: true) != .seconds(2))
}

@Test("verify backoff logic - .exponential")
func testBackoffDelayLogicExponential() async throws {
    let strategy = Backoff.Strategy.exponential(maxDelay: .seconds(3.5))
    #expect(strategy.delay(for: 0, withJitter: false) == .seconds(0))
    #expect(strategy.delay(for: 1, withJitter: false) == .seconds(1))
    #expect(strategy.delay(for: 2, withJitter: false) == .seconds(2))
    #expect(strategy.delay(for: 3, withJitter: false) == .seconds(3.5))
    #expect(strategy.delay(for: 4, withJitter: false) == .seconds(3.5))
    #expect(strategy.delay(for: 10, withJitter: false) == .seconds(3.5))

    #expect(strategy.delay(for: 2, withJitter: true) != .seconds(2))
}

@Test("verify jitter logic")
func testBackoffDelayJitter() async throws {
    for _ in 0..<100 {
        let jitterValue = Backoff.Strategy.jitterValue(base: .seconds(2), max: .seconds(2))
        // plus or minus 5 % of the base value = +/- 0.1 seconds, but never above max
        #expect(jitterValue >= .seconds(1.9))
        #expect(jitterValue <= .seconds(2.0))
    }

    for _ in 0..<100 {
        let jitterValue = Backoff.Strategy.jitterValue(base: .seconds(2), max: .seconds(3))
        // plus or minus 5 % of the base value = +/- 0.1 seconds, but never above max
        #expect(jitterValue >= .seconds(1.9))
        #expect(jitterValue <= .seconds(2.1))
    }
}
