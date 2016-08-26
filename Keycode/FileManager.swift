import Foundation

private let executableName = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String

extension FileManager {
    static func fileExists(_ path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }

    static func isDirectory(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return isDir.boolValue
    }

    static func supportDirectory(_ pathComponent: String = "") -> String {
        var path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
        path = (path as NSString).appendingPathComponent(executableName)
        return (path as NSString).appendingPathComponent(pathComponent)
    }

    static func supportDirectoryExists() -> Bool {
        let path = supportDirectory()
        return fileExists(path)
    }

    static func createSupportDirectory() throws {
        let path = supportDirectory()
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    }
}
