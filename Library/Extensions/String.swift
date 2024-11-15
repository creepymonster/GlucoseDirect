//
//  String.swift
//  GlucoseDirect
//

import CommonCrypto
import Foundation
import CryptoKit

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    func asMinuteChange() -> String {
        return String(format: LocalizedString("%1$@/min."), self)
    }
    
    func toSha256() -> String {
        let data = Data(self.utf8)
        
        let hashedData = SHA256.hash(data: data)
        return hashedData.map { String(format: "%02hhx", $0) }.joined()
    }

    func toSha1() -> String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }

        return hexBytes.joined()
    }
}
