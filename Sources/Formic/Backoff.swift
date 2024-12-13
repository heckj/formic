import Foundation

public enum RetrySetting: Sendable, Hashable, Codable {
    case none
    case retryOnFailure(Backoff)
}

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

        func delay(for attempt: Int) -> Duration {
            switch self {
            case .none:
                return .zero
            case .constant(let delay):
                return delay
            case .linear(let increment, let maxDelay):
                return min(increment * attempt, maxDelay)
            case .fibonacci(let maxDelay):
                if attempt >= Self.fibBackoffs.count {
                    return min(.seconds(610), maxDelay)
                }
                return min(.seconds(Self.fibBackoffs[attempt]), maxDelay)
            case .exponential(let maxDelay):
                if attempt >= Self.exponentialBackoffs.count {
                    return min(.seconds(512), maxDelay)
                }
                return min(.seconds(Self.exponentialBackoffs[attempt]), maxDelay)
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
        Backoff(maxRetries: 3, strategy: .fibonacci(maxDelay: .seconds(10)))
    }
}
