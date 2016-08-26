import AppKit

extension Bundle {
    static func resourceDirectory(_ pathComponent: String) -> String {
        return (Bundle.main.resourcePath! as NSString).appendingPathComponent(pathComponent)
    }
}
