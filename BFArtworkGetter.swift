//
//  BFArtworkGetter.swift
//  BFRadioPlayer
//
//  Created by Victor on 9/29/18.
//

import Foundation
import UIKit

/// Use iTunes search API 
internal class BFArtworkGetter {
    
    private let session = URLSession.shared
    private var urlTask: URLSessionDataTask?
    private var imageTask: URLSessionDataTask?
    
    init() {
        session.configuration.requestCachePolicy = .returnCacheDataElseLoad
    }
    
    func cancelRequest() {
        session.invalidateAndCancel()
    }
    
    func getArtworkUrl(query: String, preferredSize: Int = 100, completion: @escaping (_ artworkUrl: URL?) -> ()) {
        guard let utf8String = NSString(string: query).addingPercentEncoding(withAllowedCharacters: .alphanumerics), 
            let url = URL(string: "https://itunes.apple.com/search?term=" + utf8String + "&limit=1") else {
            completion(nil)
            return
        }
        urlTask?.cancel()
        urlTask = session.dataTask(with: url) { (data, response, error) in
            guard error == nil, let data = data else {
                completion(nil)
                return
            }
            
            
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            
            guard let parsedResult = json as? [String: Any],
                let results = parsedResult["results"] as? Array<[String: Any]>,
                let result = results.first,
                var artworkURL = result["artworkUrl100"] as? String else {
                    completion(nil)
                    return
            }
            if preferredSize > 100 {
                artworkURL = artworkURL.replacingOccurrences(of: "100x100", with: "\(preferredSize)x\(preferredSize)")
            }
            completion(URL(string: artworkURL))
        }
        urlTask?.resume()
    }
    
    
    func getArtworkImage(query: String, preferredSize: Int = 100, completion: @escaping (_ artworkImage: UIImage?) -> ()) {
        getArtworkUrl(query: query, preferredSize: preferredSize) { (url) in
            guard let url = url else {
                completion(nil)
                return
            }
            self.imageTask?.cancel()
            self.imageTask = self.session.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    completion(UIImage(data: data))
                } else {
                    completion(nil)
                }
            }
            self.imageTask?.resume()
        }
    }
    
}
