//
//  LocalizedBundleString.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 29.07.21. 
//

import Foundation

class FrameworkBundle {
    static let main = Bundle(for: FrameworkBundle.self)
}

public func LocalizedString(_ key: String, tableName: String? = nil, value: String? = nil, comment: String) -> String {
    if let value = value {
        return NSLocalizedString(key, tableName: tableName, bundle: FrameworkBundle.main, value: value, comment: comment)
    } else {
        return NSLocalizedString(key, tableName: tableName, bundle: FrameworkBundle.main, comment: comment)
    }
}

extension DefaultStringInterpolation {
    mutating func appendInterpolation<T>(_ optional: T?) {
        appendInterpolation(String(describing: optional))
    }
}
