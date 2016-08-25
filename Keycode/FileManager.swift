import Foundation

enum FileError : Error {
    case notFound
}

private let executableName = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String

extension FileManager {
    static func supportDirectory(_ pathComponent: String = "") throws -> String {
        return try FileManager.default.getDirectory(
            directory: .applicationSupportDirectory,
            domain: .userDomainMask,
            append: (executableName as NSString).appendingPathComponent(pathComponent)
        )
    }

    static func isDirectory(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return isDir.boolValue
    }

    private func getDirectory(directory: SearchPathDirectory, domain: SearchPathDomainMask, append: String?) throws -> String {
        let paths = NSSearchPathForDirectoriesInDomains(directory, domain, true)

        guard var resolvedPath = paths.first else {
            throw FileError.notFound
        }

        if let append = append {
            resolvedPath = (resolvedPath as NSString).appendingPathComponent(append)
        }

        try createDirectory(atPath: resolvedPath, withIntermediateDirectories: true)

        return resolvedPath
    }
}
