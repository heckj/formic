import Foundation

extension Pipe {
    /// Returns the data within the pipe as a UTF-8 encoded string, if available.
    public func string() throws -> String? {
        guard let data = try self.fileHandleForReading.readToEnd() else {
            return nil
        }
        guard let stringValue = String(data: data, encoding: String.Encoding.utf8) else {
            return nil
        }
        return stringValue
    }
}
