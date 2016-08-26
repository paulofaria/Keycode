import Foundation

enum Method: String {
    case GET
    case POST
}

class Service {
    
    typealias CompletionJSON = (_ error: Error?, _ json: Any?) -> Swift.Void
    typealias CompletionFile = (_ error: Error?, _ data: Data?) -> Swift.Void
    
    static func request(with url: String, method: Method, completion: CompletionJSON) {
        guard let url = URL(string: url) else {
            return
        }
        
        var request: URLRequest = URLRequest(url: url);
        request.httpMethod = method.rawValue
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard error == nil,
                let data = data
                else {
                    print("error=\(error)")
                    return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    completion(nil, json)
                }
            }
            catch let error as NSError {
                completion(error, nil)
            }
        }
        
        task.resume()
    }
    
    static func download(with url: String, completion: CompletionFile) -> URLSessionDownloadTask? {
        guard let url = URL(string: url) else {
            return nil
        }
        
        var request: URLRequest = URLRequest(url: url);
        request.httpMethod = Method.GET.rawValue
        
        let task = URLSession.shared.downloadTask(with: request) { (url, response, error) in

            guard error == nil, let url = url else {
                    completion(error, nil)
                    return
            }
            
            guard let data = try? Data(contentsOf: url) else {
                completion(error, nil)
                return
            }
            
            completion(error, data)
        }
        
        task.resume()
        
        return task
    }
}
