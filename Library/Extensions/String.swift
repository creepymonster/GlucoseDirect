//
//  String.swift
//  GlucoseDirect
//

import CommonCrypto
import Foundation

extension String {
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
