//
//  OSCAddressPattern.swift
//  CoreOSC
//
//  Created by Sam Smallman on 29/07/2021.
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

/// An object that represents the full path to one or more OSC Methods through pattern matching.
public struct OSCAddressPattern: Hashable, Equatable {
    
    /// The full path to one or more OSC Methods.
    public let fullPath: String

    /// The names of all the containers, in order, along the path from the root of the tree to the OSC Methods.
    public let parts: [String]

    /// The name of one or more OSC Methods the address pattern is pointing to.
    public let methodName: String

    /// An OSC Address Pattern.
    ///
    /// An OSC Address Pattern begins with the character ‘/’ followed by the symbolic ASCII names of all the containers,
    /// in order, along the path from the root of the tree to one or more OSC Methods, separated by forward slash characters,
    /// followed by the name of the OSC Methods.
    ///
    /// An OSC Address Pattern is different to an OSC Address in that it can contain wildcard characters
    /// and it is used to invoke one more OSC Methods in an OSC Address Space.
    ///
    /// Printable ASCII characters not allowed in names of OSC Methods or OSC Containers:
    /// - ' ' - Space
    /// - \# - Hash
    ///
    /// Wildcards:
    /// 1. ‘*’ in the OSC Address Pattern matches any sequence of zero or more characters.
    /// 2. ‘?’ in the OSC Address Pattern matches any single character.
    /// 3. A string of characters in square brackets (e.g., “[string]”) in the OSC Address Pattern matches any character in the string.
    ///   Inside square brackets, the minus sign (-) and exclamation point (!) have special meanings:
    ///     - two characters separated by a minus sign indicate the range of characters between the given two in ASCII collating sequence.
    ///       (A minus sign at the end of the string has no special meaning.)
    ///     - An exclamation point at the beginning of a bracketed string negates the sense of the list,
    ///       meaning that the list matches any character not in the list.
    ///       (An exclamation point anywhere besides the first character after the open bracket has no special meaning.)
    /// 4. A comma-separated list of strings enclosed in curly braces (e.g., “{foo,bar}”) in the OSC Address Pattern matches any of the strings in the list.
    /// 5. Any other character in an OSC Address Pattern can match only the same character.
    ///
    /// - Parameter addressPattern: The full path to one or more OSC Methods.
    /// - Throws: `OSCAddressError` if the format of the given address pattern is invalid.
    public init(_ addressPattern: String) throws {
        let regex = "^\\/(?:(?![ #])[\\x00-\\x7F])+$"
        if NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: addressPattern) {
            self.fullPath = addressPattern
            var addressParts = addressPattern.components(separatedBy: "/")
            addressParts.removeFirst()
            self.parts = addressParts
            self.methodName = addressParts.last ?? ""
        } else {
            throw OSCAddressError.invalidAddress
        }
    }
    
    internal init(raw addressPattern: String) {
        self.fullPath = addressPattern
        var addressParts = addressPattern.components(separatedBy: "/")
        addressParts.removeFirst()
        self.parts = addressParts
        self.methodName = addressParts.last ?? ""
    }
    
    /// Evaluate an OSC Address Pattern.
    /// - Parameter addressPattern: A `String` to be validated.
    /// - Returns: A `Result` that represents either the given string is valid, returning success,
    ///            or that the given string is invalid returning a failure containing the `OSCAddressError`.
    public static func evaluate(with addressPattern: String) -> Result<String, OSCAddressError> {
        guard addressPattern.hasPrefix("/") else { return .failure(.forwardSlash) }
        for character in addressPattern {
            guard character.isASCII == true else { return .failure(.ascii) }
            guard character != " " else { return .failure(.space) }
            guard character != "#" else { return .failure(.hash) }
        }
        return .success(addressPattern)
    }
    
}
