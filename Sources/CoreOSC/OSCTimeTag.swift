//
//  OSCTimeTag.swift
//  CoreOSC
//
//  Created by Sam Smallman on 22/107/2021.
//  Copyright © 2021 Sam Smallman. https://github.com/SammySmallman
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public struct OSCTimeTag: OSCArgumentProtocol, Equatable {
    
    /// Creates an OSC Time Tag initialized to immediately.
    public static let immediate: OSCTimeTag = OSCTimeTag()

    public var oscData: Data { Data(seconds.bigEndian.data + fraction.bigEndian.data) }

    public var oscTypeTag: Character { "t" }

    public let seconds: UInt32
    public let fraction: UInt32
    public let immediate: Bool

    public init?(data: Data) {
        guard data.count == 8 else { return nil }
        let secondsNumber = data.subdata(in: data.startIndex ..< data.startIndex + 4)
            .withUnsafeBytes { $0.load(as: UInt32.self) }
            .byteSwapped
        let fractionNumber = data.subdata(in: data.startIndex + 4 ..< data.startIndex + 8)
            .withUnsafeBytes { $0.load(as: UInt32.self) }
            .byteSwapped
        self.seconds = secondsNumber
        self.fraction = fractionNumber
        self.immediate = secondsNumber == 0 && fractionNumber == 1
    }

    public init(date: Date) {
        // OSCTimeTags uses 1900 as it's marker.
        // We need to get the seconds from 1900 not 1970 which Apple's Date Object gets.
        // Seconds between 1900 and 1970 = 2208988800
        let secondsSince1900 = date.timeIntervalSince1970 + 2208988800
        // Bitwise AND operator to get the first 32 bits of secondsSince1900 which is cast from a double to UInt64
        self.seconds = UInt32(UInt64(secondsSince1900) & 0xffffffff)
        let fractionsPerSecond = Double(0xffffffff)
        self.fraction = UInt32(fmod(secondsSince1900, 1.0) * fractionsPerSecond)
        self.immediate = false
    }

    // immediate Time Tag
    internal init() {
        self.seconds = 0
        self.fraction = 1
        self.immediate = true
    }

    public func date() -> Date {
        let date1900 = Date(timeIntervalSince1970: -2208988800)
        var interval = TimeInterval(seconds)
        interval += TimeInterval(Double(fraction) / 0xffffffff)
        return date1900.addingTimeInterval(interval)
    }

    public func hex() -> String {
        let seconds = seconds.byteArray()
            .map { String(format: "%02X", $0) }
            .joined()
        let fration = fraction.byteArray()
            .map { String(format: "%02X", $0) }
            .joined()
        return seconds + fration
    }

    public func oscAnnotation(withType type: Bool = true) -> String {
        "\(self.hex())\(type ? "(\(oscTypeTag))" : "")"
    }

}
