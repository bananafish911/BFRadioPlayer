//
//  Helpers.swift
//  BFRadioPlayer
//
//  Created by Victor on 9/29/18.
//

import Foundation
import AVFoundation

internal extension NotificationCenter {
    
    func addObserver(forName name: NSNotification.Name, using block: @escaping (Notification) -> Void) {
        addObserver(forName: name, object: nil, queue: nil, using: block)
    }
    
    /// DispatchQueue.main
    func postOnMainQueue(name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable : Any]? = nil) {
        DispatchQueue.main.async {
            self.post(name: name, object: object, userInfo: userInfo)
        }
    }
}

internal extension AVPlayerItem {
    
    var isUrlPlayable: Bool {
        guard let urlAsset = asset as? AVURLAsset else {
            return false
        }
        return urlAsset.isPlayable
    }
    
}

internal extension AVMetadataItem {
    
    /// stringValue: ISO-8859-1 → UTF-8
    var utf8String: String? {
        guard let data = stringValue?.data(using: String.Encoding.isoLatin1, allowLossyConversion: true) else {
            return nil
        }
        return String(data: data as Data, encoding: String.Encoding.utf8)
    }
}
