import Foundation

/// Loads recorded JSON answers from `SenpengTests/Fixtures`.
enum Fixture {

    /// Errors when a fixture can't be loaded.
    enum LoadError: Error {
        /// No file with this name exists in the test bundle.
        case notFound(String)
    }

    /// Reads a JSON fixture from the test bundle.
    /// - Parameter name: The file name without `.json`.
    /// - Returns: The file's contents.
    static func data(named name: String) throws -> Data {
        guard let url = Bundle(for: BundleToken.self).url(forResource: name, withExtension: "json") else {
            throw LoadError.notFound(name)
        }
        return try Data(contentsOf: url)
    }
}

/// A class in the test bundle, used only to find that bundle.
private final class BundleToken {}
