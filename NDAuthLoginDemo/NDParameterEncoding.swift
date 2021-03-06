//
//  NDParameterEncoding.swift
//  NDAuthLoginDemo
//
//  Created by 梁宪松 on 2020/8/7.
//  Copyright © 2020 madao. All rights reserved.
//

import UIKit

/// A dictionary of parameters to apply to a `URL`.
public typealias Parameters = [String: Any]

/// A type used to define how a set of parameters are applied to a `URL`.
public protocol NDParameterEncoding {
    /// Creates a URL by encoding parameters and applying them onto an existing URL.
    ///
    /// - parameter url: The URL to have parameters applied.
    /// - parameter parameters: The parameters to apply.
    ///
    /// - returns: The encoded request.
    func encode(_ url: URL, with parameters: Parameters?) throws -> URL
}

class NDURLEncoding: NDParameterEncoding {
    
    /// Configures how `Array` parameters are encoded.
    ///
    /// - brackets:        An empty set of square brackets is appended to the key for every value.
    ///                    This is the default behavior.
    /// - noBrackets:      No brackets are appended. The key is encoded as is.
    public enum ArrayEncoding {
        case brackets, noBrackets

        func encode(key: String) -> String {
            switch self {
            case .brackets:
                return "\(key)[]"
            case .noBrackets:
                return key
            }
        }
    }

    /// Configures how `Bool` parameters are encoded.
    ///
    /// - numeric:         Encode `true` as `1` and `false` as `0`. This is the default behavior.
    /// - literal:         Encode `true` and `false` as string literals.
    public enum BoolEncoding {
        case numeric, literal

        func encode(value: Bool) -> String {
            switch self {
            case .numeric:
                return value ? "1" : "0"
            case .literal:
                return value ? "true" : "false"
            }
        }
    }
    
    // MARK: Properties
    /// The encoding to use for `Array` parameters.
    public var arrayEncoding: ArrayEncoding

    /// The encoding to use for `Bool` parameters.
    public let boolEncoding: BoolEncoding
    
    public func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []

        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }
    
    public func queryComponents(_ parameters: [String: Any]) -> [(String, String)] {
        var components: [(String, String)] = []

        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }
        return components
    }
    
    /// Creates percent-escaped, URL encoded query string components from the given key-value pair using recursion.
    ///
    /// - parameter key:   The key of the query component.
    /// - parameter value: The value of the query component.
    ///
    /// - returns: The percent-escaped, URL encoded query string components.
    public func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []

        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(fromKey: arrayEncoding.encode(key: key), value: value)
            }
        } else if let value = value as? NSNumber {
            if value.isBool {
                components.append((escape(key), escape(boolEncoding.encode(value: value.boolValue))))
            } else {
                components.append((escape(key), escape("\(value)")))
            }
        } else if let bool = value as? Bool {
            components.append((escape(key), escape(boolEncoding.encode(value: bool))))
        } else {
            components.append((escape(key), escape("\(value)")))
        }

        return components
    }
    
    /// Returns a percent-escaped string following RFC 3986 for a query string key or value.
    ///
    /// RFC 3986 states that the following characters are "reserved" characters.
    ///
    /// - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
    /// - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
    ///
    /// In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
    /// query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
    /// should be percent-escaped in the query string.
    ///
    /// - parameter string: The string to be percent-escaped.
    ///
    /// - returns: The percent-escaped string.
    public func escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

        var escaped = ""

        //==========================================================================================================
        //
        //  Batching is required for escaping due to an internal bug in iOS 8.1 and 8.2. Encoding more than a few
        //  hundred Chinese characters causes various malloc error crashes. To avoid this issue until iOS 8 is no
        //  longer supported, batching MUST be used for encoding. This introduces roughly a 20% overhead. For more
        //  info, please refer to:
        //
        //      - https://github.com/Alamofire/Alamofire/issues/206
        //
        //==========================================================================================================

        if #available(iOS 8.3, *) {
            escaped = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
        } else {
            let batchSize = 50
            var index = string.startIndex

            while index != string.endIndex {
                let startIndex = index
                let endIndex = string.index(index, offsetBy: batchSize, limitedBy: string.endIndex) ?? string.endIndex
                let range = startIndex..<endIndex

                let substring = string[range]

                escaped += substring.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? String(substring)

                index = endIndex
            }
        }

        return escaped
    }

    // MARK: Initialization

    /// Creates a `NDURLEncoding` instance using the specified destination.
    ///
    /// - parameter arrayEncoding: The encoding to use for `Array` parameters.
    /// - parameter boolEncoding: The encoding to use for `Bool` parameters.
    ///
    /// - returns: The new `URLEncoding` instance.
    public init(arrayEncoding: ArrayEncoding = .brackets, boolEncoding: BoolEncoding = .numeric) {
        self.arrayEncoding = arrayEncoding
        self.boolEncoding = boolEncoding
    }
    
    // MARK: Encoding

    /// Creates a URL by encoding parameters and applying them onto an existing request.
    ///
    /// - parameter url: The URL to have parameters applied.
    /// - parameter parameters: The parameters to apply.
    ///
    /// - throws: An `Error` if the encoding process encounters an error.
    ///
    /// - returns: The encoded URL.
    func encode(_ url: URL, with parameters: Parameters?) -> URL {
        
        var mUrl = url
        guard let parameters = parameters else {
            return url
        }
         
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
            
            for (key, value) in queryComponents(parameters) {
                
                if urlComponents.queryItems == nil {
                    urlComponents.queryItems = []
                }
                urlComponents.queryItems?.append(URLQueryItem.init(name: key, value: value))
            }
            mUrl = urlComponents.url ?? url
        }
        
        return mUrl
    }
    
    // MARK: Decoding
    
    /// Decode Parameters from URL
    /// - Parameter url: The URL to decode parameters.
    ///
    /// - returns: decoded parameters.
    static func decode(_ url: URL) -> Parameters {
        
        var params: Parameters = [:]

        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = urlComponents.queryItems {
            
            for item in queryItems {
                
                params[item.name] = item.value
            }
        }
        
        return params
    }
}


// MARK: -

extension NSNumber {
    fileprivate var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}
