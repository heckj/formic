//#if canImport(FoundationEssentials)
//import FoundationEssentials
//#else
import Foundation
//#endif

extension Pipe {
    func string() -> String? {
        let data = self.fileHandleForReading.readDataToEndOfFile()
        let result: String?
        if let string = String(data: data, encoding: String.Encoding.utf8) {
            result = string
        } else {
            result = nil
        }
        return result
    }
}
