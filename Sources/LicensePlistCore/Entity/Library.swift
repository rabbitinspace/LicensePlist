import Foundation

public protocol Library: HasName, Hashable {
    var version: String? { get }
}

extension Library {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
