//
//  AttributedParser.swift
//  SyntaxKit
//
//  A subclass of Parser that knows about themes. Using the theme it maps
//  between recognized TextMate scope descriptions and NSAttributedString
//  attributes.
//
//  Created by Sam Soffes on 9/24/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

public class AttributedParser : Parser {
    
    // MARK: - Types
    
    public typealias AttributedCallback = (_ scope: String, _ range: NSRange, _ attributes: Attributes?) -> Void

    
    // MARK: - Properties

    public var theme: Theme
    
    
    // MARK: - Initializers
    
    public required init(language: Language, theme: Theme) {
        self.theme = theme
        super.init(language: language)
    }
    
    
    // MARK: - Parsing
    
    public func parse(_ string: String, match callback: AttributedCallback) {
        parse(string) { scope, range in
            callback(scope, range, self.attributesForScope(scope))
        }
    }
    
    func parse(_ incremental: (range: NSRange, diff: Diff, previousScopes: ScopedString)? = nil, match callback: AttributedCallback) -> ScopedString? {
        return parse(incremental) { scope, range in
            callback(scope, range, self.attributesForScope(scope))
        }
    }
    
    public func attributedStringForString(_ string: String, baseAttributes: Attributes? = nil) -> NSAttributedString {
        let output = NSMutableAttributedString(string: string as String, attributes: baseAttributes)
        output.beginEditing()
        parse(string) { _, range, attributes in
            if let attributes = attributes {
                output.addAttributes(attributes, range: range)
            }
        }
        output.endEditing()
        return output
    }
    
    
    // MARK: - Private
    
    private func attributesForScope(_ scope: String) -> Attributes? {
        let components = scope.components(separatedBy: ".") as NSArray
        let count = components.count

        if count == 0 {
            return nil
        }

        var attributes = Attributes()
        
        for i in 0 ..< count {
            let key = (components.subarray(with: NSMakeRange(0, i + 1)) as NSArray).componentsJoined(by: ".")
            if let attrs = theme.attributes[key] {
                for (k, v) in attrs {
                    attributes[k] = v
                }
            }
        }
        
        if attributes.isEmpty {
            return nil
        }
        
        return attributes
    }
}
