import Foundation

extension Pipe {
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
