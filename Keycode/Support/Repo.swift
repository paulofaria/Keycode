import Foundation

struct Repo {
    var name: String?
    var archive: String?
    
    init(json: [String: Any]?) {
        guard let json = json else {
            return
        }
        
        if let name = json["name"] as? String {
            self.name = name
        }
        
        if let archive = json["archive_url"] as? String {
            self.archive = archive
        }
    }
}
