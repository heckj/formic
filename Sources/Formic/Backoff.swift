import Foundation

/// The backoff settings for a command.
public struct Backoff: Sendable, Hashable, Codable {

    /// The maximum number of retries to attempt on failure.
    public let maxRetries: Int
    /// The delay strategy for waiting between retries.
    public let strategy: Strategy

    /// The backoff strategy and values for delaying.
    public enum Strategy: Sendable, Hashable, Codable {
        // precomputed fibonacci backoffs for up to 16 attempts
        // max delay of ~5 minutes seemed completely reasonable
        static let fibBackoffs: [Double] = [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610]
        static let exponentialBackoffs: [Double] = [0, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512]
        /// No delay, retry immediately.
        case none
        /// Always delay by the same amount.
        case constant(delay: TimeInterval)
        /// Increment delay by a constant amount, up to a max interval.
        case linear(increment: TimeInterval, maxDelay: TimeInterval)
        /// Increment delay by a backoff increasing using a fibonacci sequence, up to a max interval.
        case fibonacci(maxDelay: TimeInterval)
        /// Increment delay by a backoff increasing using a exponential sequence, up to a max interval.
        case exponential(maxDelay: TimeInterval)

        func delay(for attempt: Int) -> TimeInterval {
            switch self {
            case .none:
                return 0
            case .constant(let delay):
                return delay
            case .linear(let increment, let maxDelay):
                return min(Double(attempt) * increment, maxDelay)
            case .fibonacci(let maxDelay):
                if attempt >= Self.fibBackoffs.count {
                    return min(610, maxDelay)
                }
                return min(Self.fibBackoffs[attempt], maxDelay)
            case .exponential(let maxDelay):
                if attempt >= Self.exponentialBackoffs.count {
                    return min(512, maxDelay)
                }
                return min(Self.exponentialBackoffs[attempt], maxDelay)
            }
        }
    }

    /// Creates a new backup setting with the values you provide.
    /// - Parameters:
    ///   - maxRetries: The maximum number of retry attempts allowed.
    ///   - strategy: The delay strategy for waiting between retries.
    public init(maxRetries: Int, strategy: Strategy) {
        self.maxRetries = maxRetries
        self.strategy = strategy
    }

    /// Default backoff settings
    ///
    /// Attempt up to 3 retries, with a growing backoff with a maximum of 60 seconds.
    public static var `default`: Backoff {
        Backoff(maxRetries: 3, strategy: .fibonacci(maxDelay: 10))
    }
}
