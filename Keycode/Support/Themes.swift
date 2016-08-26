import Foundation

struct Themes {
    typealias CompletionListThemes = (_ error: Error?, _ themes: [Repo]?) -> Swift.Void
    
    static func list(completion: CompletionListThemes) {
        
        let url = "https://api.github.com/search/repositories?q=.tmbundle%20in:name%20user:textmate&sort=stars&order=desc"
        
        Service.request(with: url, method: .GET) { error, json in
            guard error == nil else {
                completion(error, nil)
                return
            }
            
            guard let json = json as? [String: Any] else {
                return
            }
            
            var themes: [Repo] = []
            if let items = json["items"] as? [[String: Any]], items.count > 0 {
                themes = items.map { Repo(json: $0) }
            }
            
            completion(nil, themes)
        }
    }
}
