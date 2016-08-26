import Foundation

private let executableName = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String

extension FileManager {
    static func isDirectory(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return isDir.boolValue
    }

    static func supportDirectory(_ pathComponent: String = "") throws -> String {
        var path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!

        path = (path as NSString).appendingPathComponent(executableName)
        path = (path as NSString).appendingPathComponent(pathComponent)

        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }
}
