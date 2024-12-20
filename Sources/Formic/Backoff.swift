import Foundation

/// The retry and backoff delay settings for a command.
public struct Backoff: Sendable, Hashable, Codable {

    /// The maximum number of retries to attempt on failure.
    public let maxRetries: Int

    /// The delay strategy for waiting between retries.
    public let strategy: Strategy

    public var retryOnFailure: Bool {
        maxRetries > 0
    }

    /// The backoff strategy and values for delaying.
    public enum Strategy: Sendable, Hashable, Codable {
        // precomputed fibonacci backoffs for up to 16 attempts
        // max delay of ~5 minutes seemed completely reasonable
        static let fibBackoffs: [Int] = [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610]
        static let exponentialBackoffs: [Int] = [0, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512]
        /// No delay, retry immediately.
        case none
        /// Always delay by the same amount.
        case constant(delay: Duration)
        /// Increment delay by a constant amount, up to a max interval.
        case linear(increment: Duration, maxDelay: Duration)
        /// Increment delay by a backoff increasing using a fibonacci sequence, up to a max interval.
        case fibonacci(maxDelay: Duration)
        /// Increment delay by a backoff increasing using a exponential sequence, up to a max interval.
        case exponential(maxDelay: Duration)

        func delay(for attempt: Int, withJitter: Bool) -> Duration {
            switch self {
            case .none:
                return .zero
            case .constant(let delay):
                return delay
            case .linear(let increment, let maxDelay):
                if withJitter {
                    return Self.jitterValue(base: increment * attempt, max: maxDelay)
                } else {
                    return min(increment * attempt, maxDelay)
                }
            case .fibonacci(let maxDelay):
                if attempt >= Self.fibBackoffs.count {
                    if withJitter {
                        return Self.jitterValue(base: .seconds(610), max: maxDelay)
                    } else {
                        return min(.seconds(610), maxDelay)
                    }
                }
                if withJitter {
                    return Self.jitterValue(base: .seconds(Self.fibBackoffs[attempt]), max: maxDelay)
                } else {
                    return min(.seconds(Self.fibBackoffs[attempt]), maxDelay)
                }
            case .exponential(let maxDelay):
                if attempt >= Self.exponentialBackoffs.count {
                    if withJitter {
                        return Self.jitterValue(base: .seconds(512), max: maxDelay)
                    } else {
                        return min(.seconds(512), maxDelay)
                    }
                }
                if withJitter {
                    return Self.jitterValue(base: .seconds(Self.exponentialBackoffs[attempt]), max: maxDelay)
                } else {
                    return min(.seconds(Self.exponentialBackoffs[attempt]), maxDelay)
                }
            }
        }

        static func jitterValue(base: Duration, max: Duration) -> Duration {
            // plus or minus 5% of the base duration
            let jitter: Duration = base * Double.random(in: -1...1) / 20
            let adjustedDuration = base + jitter
            if adjustedDuration > max {
                return max
            } else if adjustedDuration < .zero {
                return .zero
            } else {
                return adjustedDuration
            }
        }
    }

    /// Creates a new backup setting with the values you provide.
    /// - Parameters:
    ///   - maxRetries: The maximum number of retry attempts allowed. Negative integers are treated as 0 retries.
    ///   - strategy: The delay strategy for waiting between retries.
    public init(maxRetries: Int, strategy: Strategy) {
        self.maxRetries = max(maxRetries, 0)
        self.strategy = strategy
    }

    /// Never attempt retry
    ///
    /// Do not attempt to retry on failure.
    public static var never: Backoff {
        Backoff(maxRetries: 0, strategy: .none)
    }

    /// Default backoff settings
    ///
    /// Attempt up to 3 retries, with a growing backoff with a maximum of 60 seconds.
    public static var `default`: Backoff {
        Backoff(maxRetries: 3, strategy: .fibonacci(maxDelay: .seconds(10)))
    }

}
