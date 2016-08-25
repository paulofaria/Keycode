//
//  ScopedString.swift
//  SyntaxKit
//
//  A datastructure that facilitates working with strings that have nested 
//  scopes associated with them. A scope being a named range that can have an
//  attribute assciated with it for the callers convenience.
//  The ranges can be nested. The datastructure could be visualized like this:
//  In fact, something like this is returned by the prettyPrint function.
//  
//  Top:                              ----
//                              -------------
//            -------   -----------------------------
//  Bottom:  ------------------------------------------
//  String: "(This is) (string (with (nest)ed) scopes)!"
//  
//  Note:
//  In the picture above the parens are not actually in the string, they serve 
//  visualization purposes. The bottom-most layer is implicit and is not stored.
//  A new layer is added if no layer can hold the inserted scope without
//  creating intersections.
//
//  In the future the datastructure could be optimized by using binary search
//  for insertions at the individual levels.
//
//  Created by Alexander Hedges on 29/01/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

import Foundation

extension NSRange {
    
    func isEmpty() -> Bool {
        return length == 0
    }
    
    func containsIndex(_ index: Int) -> Bool {
        return length == 0 && index == location || index >= location && index < location + length
    }
    
    func partiallyContainsRange(_ otherRange: NSRange) -> Bool {
        return otherRange.location + otherRange.length >= location && otherRange.location < location + length
    }
    
    func entirelyContainsRange(_ otherRange: NSRange) -> Bool {
        return location <= otherRange.location && location + length >= otherRange.location + otherRange.length
    }
    
    /// Removes the indexes contained in range from self and shifts itself as
    /// needed to not leave a gap in the domain.
    mutating func removeIndexesFromRange(_ range: NSRange) {
        length -= NSIntersectionRange(range, NSRange(location: location, length: length)).length
        if (range.location < self.location) {
            self.location -= NSIntersectionRange(range, NSRange(location: 0, length: self.location)).length
        }
    }
    
    /// Inserts the indexes contained in range into self. Grows as needed.
    mutating func insertIndexesFromRange(_ range: NSRange) {
        if self.containsIndex(range.location) && range.location < NSMaxRange(self) {
            length += range.length
        } else if location > range.location {
            location += range.length
        }
    }
}

/// In this project the difference between a Result and a Scope is that the
/// scope has the attribute set while the Result does not. This is an implicit
/// agreement, please respect.
typealias Scope = Result

public struct ScopedString {
    
    // MARK: - Properties
    
    var underlyingString: String
    
    private var levels: [[Scope]] = []
    
    var baseScope: Scope {
        return Scope(identifier: "BaseNameString", range: NSRange(location: 0, length: (underlyingString as NSString).length), attribute: nil)
    }
    
    
    // MARK: - Initializers
    
    init(string: String) {
        self.underlyingString = string
    }
    
    
    // MARK: - Interface
    
    func numberOfScopes() -> Int {
        var sum = 1
        for level in levels {
            sum += level.count
        }
        return sum
    }
    
    func numberOfLevels() -> Int {
        return levels.count + 1
    }
    
    func isInString(_ index: Int) -> Bool {
        return index >= 0 && index <= baseScope.range.length
    }
    
    mutating func addScopeAtTop(_ scope: Scope) {
        assert(scope.range.length != 0)
        assert(NSIntersectionRange(scope.range, baseScope.range).length == scope.range.length)
        
        var added = false
        for level in 0..<levels.count {
            if findScopeIntersectionWithRange(scope.range, atLevel: levels[level]) == nil {
                levels[level].insert(scope, at: self.insertionPointForRange(scope.range, atLevel: levels[level]))
                added = true
                break
            }
        }
        if !added {
            levels.append([scope])
        }
    }
    
    mutating func addScopeAtBottom(_ scope: Scope) {
        assert(scope.range.length != 0)
        assert(NSIntersectionRange(scope.range, baseScope.range).length == scope.range.length)
        
        var added = false

        for level in stride(from: (levels.count - 1), to: 0, by: -1) {
            if findScopeIntersectionWithRange(scope.range, atLevel: levels[level]) == nil {
                levels[level].insert(scope, at: self.insertionPointForRange(scope.range, atLevel: levels[level]))
                added = true
                break
            }
        }
        if !added {
            levels.insert([scope], at: 0)
        }
    }
    
    func topmostScopeAtIndex(_ index: Int) -> Scope {
        let indexRange = NSRange(location: index, length: 0)
        for i in stride(from: (levels.count - 1), to: 0, by: -1) {
            let level = levels[i]
            if let theScope = findScopeIntersectionWithRange(indexRange, atLevel: level) {
                return theScope
            }
        }
        return baseScope
    }
    
    func lowerScopeForScope(_ scope: Scope, AtIndex index: Int) -> Scope {
        assert(index >= 0 && index <= baseScope.range.length)
        
        var foundScope = false
        let indexRange = NSRange(location: index, length: 0)
        for i in stride(from: (levels.count - 1), to: 0, by: -1) {
            let level = levels[i]
            let theScope = findScopeIntersectionWithRange(indexRange, atLevel: level)
            if theScope != nil {
                if foundScope {
                    return scope
                } else if theScope! == scope {
                    foundScope = true
                }
            }
        }
        return baseScope
    }
    
    func levelForScope(_ scope: Scope) -> Int {
        for i in 0 ..< levels.count {
            let level = levels[i]
            for currentScope in level {
                if scope == currentScope {
                    return i + 1
                }
            }
        }
        if scope == baseScope {
            return 0
        }
        return -1
    }
    
    /// Removes all scopes that are entirely contained in the spcified range.
    mutating func removeScopesInRange(_ range: NSRange) {
        assert(NSIntersectionRange(range, baseScope.range).length == range.length)
        
        for level in stride(from: (levels.count - 1), to: 0, by: -1) {
            for scope in stride(from: (levels[level].count-1), to: 0, by: -1) {
                let theScope = levels[level][scope]
                if range.entirelyContainsRange(theScope.range) {
                    levels[level].remove(at: scope)
                }
            }
            if levels[level].count == 0 {
                levels.remove(at: level)
            }
        }
    }
    
    /// Inserts the given string into the underlying string, stretching and
    /// shifting ranges as needed. If the range starts before and ends after the
    /// insertion point, it is stretched.
    mutating func insertString(_ string: String, atIndex index: Int) {
        assert(index >= 0 && index <= baseScope.range.length)
        
        let s = underlyingString as NSString
        let length = (string as NSString).length
        let mutableString = s.mutableCopy() as! NSMutableString
        mutableString.insert(string, at: index)
        self.underlyingString = mutableString.copy() as! String
        for level in 0..<levels.count {
            for scope in 0..<levels[level].count {
                levels[level][scope].range.insertIndexesFromRange(NSRange(location: index, length: length))
            }
        }
    }
    
    /// Deletes the characters from the underlying string, shrinking and
    /// deleting scopes as needed.
    mutating func deleteCharactersInRange(_ range: NSRange) {
        assert(NSIntersectionRange(range, baseScope.range).length == range.length)
        
        let mutableString = (self.underlyingString as NSString).mutableCopy() as! NSMutableString
        mutableString.deleteCharacters(in: range)
        self.underlyingString = mutableString.copy() as! String
        for level in stride(from: (levels.count - 1), to: 0, by: -1) {
            for scope in stride(from: (levels[level].count-1), to: 0, by: -1) {
                var theRange = levels[level][scope].range
                theRange.removeIndexesFromRange(range)
                if theRange.isEmpty() {
                    levels[level].remove(at: scope)
                } else {
                    levels[level][scope].range = theRange
                }
            }
            if levels[level].count == 0 {
                levels.remove(at: level)
            }
        }
    }
    
    /// - note: This representation is guaranteed not to change between releases
    ///         (except for releases with breaking changes) so it can be used
    ///         for unit testing.
    /// - returns: A user-friendly description of the instance.
    func prettyRepresentation() -> String {
        var result = ""
        var printableUnderlyingString = (underlyingString as NSString).replacingOccurrences(of: "\n", with: "¬")
        printableUnderlyingString = (printableUnderlyingString as NSString).replacingOccurrences(of: "\t", with: "»")
        result += printableUnderlyingString + "\n"
        for level in stride(from: (levels.count - 1), to: 0, by: -1) {
            var levelString = String(repeating: " ", count: (underlyingString as NSString).length)
            for pattern in levels[level] {
                let range = pattern.range
                if range.length == 0 {
                    assert(false)
                } else if range.length == 1 {
                    levelString = (levelString as NSString).replacingCharacters(in: range, with: "|")
                } else {
                    let dashes = String(repeating: "-", count: range.length - 2)
                    levelString = (levelString as NSString).replacingCharacters(in: range, with: "[\(dashes)]")
                }
            }
            result += levelString + "\n"
        }
        var numberString = ""
        for i in 0...(underlyingString as NSString).length/10 {
            let numDigits = ("\(i*10)" as NSString).length
            let dashes = String(repeating: "-", count: 9 - numDigits)
            numberString += "\(i*10)\(dashes)|"
        }
        result += numberString + "\n"
        return result
    }
    
    
    // MARK: - Private
    
    private func findScopeIntersectionWithRange(_ range: NSRange, atLevel level: [Scope]) -> Scope? {
        for scope in level {
            if scope.range.partiallyContainsRange(range) {
                return scope
            }
        }
        return nil
    }
    
    private func insertionPointForRange(_ range: NSRange, atLevel level: [Scope]) -> Int {
        var i = 0
        for scope in level {
            if range.location < scope.range.location {
                return i
            }
            i += 1
        }
        return i
    }
}
