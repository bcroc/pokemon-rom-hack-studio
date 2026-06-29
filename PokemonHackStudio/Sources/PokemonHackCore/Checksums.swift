import CryptoKit
import Foundation

func pokemonHackSHA1Hex(_ data: Data) -> String {
    Insecure.SHA1.hash(data: data)
        .map { String(format: "%02x", $0) }
        .joined()
}

func pokemonHackCRC32Hex(_ data: Data) -> String {
    String(format: "%08x", pokemonHackCRC32(data))
}

func pokemonHackCRC32(_ data: Data) -> UInt32 {
    var crc: UInt32 = 0xFFFF_FFFF
    for byte in data {
        crc ^= UInt32(byte)
        for _ in 0..<8 {
            let mask = 0 &- (crc & 1)
            crc = (crc >> 1) ^ (0xEDB8_8320 & mask)
        }
    }
    return ~crc
}
