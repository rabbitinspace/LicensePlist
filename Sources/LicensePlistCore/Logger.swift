import Foundation

struct StandardError: TextOutputStream {
    private static let handle = FileHandle.standardError

    public func write(_ string: String) {
        Self.handle.write(Data(string.utf8))
    }
}

public struct Logger {
    private static var stderr = StandardError()
    
    public static func error(_ message: String) {
        Self.log(level: "ERROR", message: message)
    }
    
    public static func warning(_ message: String) {
        Self.log(level: "WARNING", message: message)
    }

    public static func info(_ message: String) {
        Self.log(level: "INFO", message: message)
    }
    
    private static func log(level: String, message: String) {
        print("[\(level)]: \(message)", to: &Self.stderr)
    }
}
