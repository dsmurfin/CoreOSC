//
//  OSCArgumentProtocol.swift
//  CoreOSC
//
//  Created by Sam Smallman on 26/07/2021.
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

public protocol OSCArgumentProtocol {
    var oscData: Data { get }
    var oscTypeTag: Character { get }
    func oscAnnotation(withType type: Bool) -> String
}

public enum OSCArgument: OSCArgumentProtocol, CustomStringConvertible {

    case `nil`
    case impulse

    public var description: String {
        switch self {
        case .nil: return "nil"
        case .impulse: return "impulse"
        }
    }

    public var oscData: Data { Data() }

    public var oscTypeTag: Character {
        switch self {
        case .nil: return .oscTypeTagNil
        case .impulse: return .oscTypeTagImpulse
        }
    }

    public func oscAnnotation(withType type: Bool) -> String {
        "\(self)\(type ? "(\(oscTypeTag))" : "")"
    }

}

extension Int32: OSCArgumentProtocol {

    public var oscData: Data { self.bigEndian.data }

    public var oscTypeTag: Character { .oscTypeTagInt }

    public func oscAnnotation(withType type: Bool = true) -> String {
        "\(self)\(type ? "(\(oscTypeTag))" : "")"
    }

}

extension Int: OSCArgumentProtocol {

    public var oscData: Data {
        guard let int = Int32(exactly: self) else {
            return Int32(0).bigEndian.data
        }
        return int.bigEndian.data
    }

    public var oscTypeTag: Character { .oscTypeTagInt }

    public func oscAnnotation(withType type: Bool = true) -> String {
        let int = Int32(exactly: self) ?? 0
        return "\(int)\(type ? "(\(oscTypeTag))" : "")"
    }

}

extension Float32: OSCArgumentProtocol {

    public var oscData: Data {
        var float: CFSwappedFloat32 = CFConvertFloatHostToSwapped(self)
        let size: Int = MemoryLayout<CFSwappedFloat32>.size
        let result: [UInt8] = withUnsafePointer(to: &float) {
            $0.withMemoryRebound(to: UInt8.self, capacity: size) {
                Array(UnsafeBufferPointer(start: $0, count: size))
            }
        }
        return Data(result)
    }

    public var oscTypeTag: Character { .oscTypeTagFloat }

    public func oscAnnotation(withType type: Bool = true) -> String {
        "\(self)\(type ? "(\(oscTypeTag))" : "")"
    }

}

extension Double: OSCArgumentProtocol {

    public var oscData: Data {
        let floatFromDouble = Float32(exactly: self) ?? Float32(0)
        var float: CFSwappedFloat32 = CFConvertFloatHostToSwapped(floatFromDouble)
        let size: Int = MemoryLayout<CFSwappedFloat32>.size
        let result: [UInt8] = withUnsafePointer(to: &float) {
            $0.withMemoryRebound(to: UInt8.self, capacity: size) {
                Array(UnsafeBufferPointer(start: $0, count: size))
            }
        }
        return Data(result)
    }

    public var oscTypeTag: Character { .oscTypeTagFloat }

    public func oscAnnotation(withType type: Bool = true) -> String {
        "\(self)\(type ? "(\(oscTypeTag))" : "")"
    }

}

extension String: OSCArgumentProtocol {

    public var oscData: Data {
        var data = data(using: .utf8)!
        for _ in 1...4 - data.count % 4 {
            var null = UInt8(0)
            data.append(&null, count: 1)
        }
        return data
    }

    public var oscTypeTag: Character { .oscTypeTagString }

    public func oscAnnotation(withType type: Bool = true) -> String {
        if self.contains(" ") {
            return "\"\(self)\"\(type ? "(\(oscTypeTag))" : "")"
        } else {
            return "\(self)\(type ? "(\(oscTypeTag))" : "")"
        }
    }

}

extension Data: OSCArgumentProtocol {

    public var oscData: Data {
        let length = UInt32(count)
        var data = Data()
        data.append(length.bigEndian.data)
        data.append(self)
        while data.count % 4 != 0 {
            var null = UInt8(0)
            data.append(&null, count: 1)
        }
        return data
    }

    public var oscTypeTag: Character { .oscTypeTagBlob }

    public func oscAnnotation(withType type: Bool = true) -> String {
        "\(self.count)\(type ? "(\(oscTypeTag))" : "")"
    }

}

extension Bool: OSCArgumentProtocol {

    public var oscData: Data { Data() }

    public var oscTypeTag: Character { self == true ? .oscTypeTagTrue : .oscTypeTagFalse }

    public func oscAnnotation(withType type: Bool = true) -> String {
        "\(self)\(type ? "(\(oscTypeTag))" : "")"
    }

}
