//
//  Parser.swift
//  SyntaxKit
//
//  This class is in charge of the painful task of recognizing the syntax
//  patterns. It tries to match parsing behavior of TextMate as closely as
//  possible.
//
//  Created by Sam Soffes on 9/19/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

public class Parser {
    
    // MARK: - Types

    public typealias Callback = (_ scope: String, _ range: NSRange) -> Void


    // MARK: - Properties

    public let language: Language

    var string = ""
    var aborted = false


    // MARK: - Initializers

    public init(language: Language) {
        self.language = language
    }


    // MARK: - Public

    public func parse(_ string: String, match callback: Callback) {
        if aborted { return }

        self.string = string
        parse(match: callback)
        self.string = ""
    }


    // MARK: - Private

    /// Parses the string. Supports incremental parsing.
    ///
    /// The given range mey be exceeded if necessary to match a pattern entirely.
    ///
    /// - parameter incremental: A tuple containing all the information
    ///             necessary for incremental parsing. A range in which to parse,
    ///             a Diff representing the change and the result of the
    ///             previous call to parse.
    /// - parameter callback: The callback to call on every match of a pattern
    ///             identifier of the language.
    /// - returns: A ScopedString that contains the range results of the parsing
    ///            Or nil if the parsing was aborted.
    @discardableResult
    public func parse(_ incremental: (range: NSRange, diff: Diff, previousScopes: ScopedString)? = nil, match callback: Callback) -> ScopedString? {
        let bounds: NSRange
        var scopesString: ScopedString
        var endScope: Scope?
        if incremental != nil && incremental!.previousScopes.underlyingString != (string as NSString).replacingCharacters(in: incremental!.diff.range, with: incremental!.diff.change) {
            bounds = incremental!.range
            scopesString = incremental!.previousScopes
            endScope = scopesString.topmostScopeAtIndex(bounds.location)
            if incremental!.diff.range.length == 0 {
                scopesString.insertString(incremental!.diff.change, atIndex: incremental!.diff.range.location)
            } else {
                scopesString.deleteCharactersInRange(incremental!.diff.range)
            }
        } else {
            bounds = NSRange(location: 0, length: (string as NSString).length)
            scopesString = ScopedString(string: string)
        }

        var startIndex = bounds.location
        var endIndex = NSMaxRange(bounds)
        let allResults = ResultSet(startingRange: bounds)

        while startIndex < endIndex {
            let endPattern = endScope?.attribute as! Pattern?
            guard let results = self.matchSubpatternsOfPattern(endPattern ?? language.pattern, inRange: NSRange(location: startIndex, length: endIndex - startIndex)) else {
                return nil
            }

            if endScope != nil {
                allResults.addResult(Result(identifier: endScope!.patternIdentifier, range: results.range))
            }

            if results.range.length != 0 {
                allResults.addResults(results)
                startIndex = NSMaxRange(results.range)
                if endScope != nil {
                    endScope = scopesString.lowerScopeForScope(endScope!, AtIndex: startIndex)
                }
            } else {
                startIndex = endIndex
            }

            if startIndex > endIndex && scopesString.isInString(startIndex + 1) {
                let scopeAtIndex = scopesString.topmostScopeAtIndex(startIndex + 1)
                if endScope == nil && scopesString.levelForScope(scopeAtIndex) > 0 ||
                    endScope != nil && scopesString.levelForScope(scopeAtIndex) > scopesString.levelForScope(endScope!) {
                    endIndex = NSMaxRange(scopeAtIndex.range)
                }
            }
        }

        if aborted { return nil }

        scopesString.removeScopesInRange(allResults.range)
        self.applyResults(allResults, storingInScopesString: &scopesString, callback: callback)
        return scopesString
    }

    // Algorithmic notes:
    // A pattern expression can not match a substring spanning multiple lines
    // so in the outer loop the string is decomposed into its lines.
    // In the inner loop it tries to repeatedly match a pattern followed by the
    // end pattern until either the line is consumed or it has found the end.
    // This procedure is repeated with the subsequent lines until it has either
    // matched the end pattern or the string is consumed entirely.
    // If it can find neither in a line it moves to the next one.

    // Implementation note:
    // The matching of the middle part may return a match that goes beyond the
    // given range. This is intentional.

    /// Matches subpatterns of the given pattern in the input.
    ///
    /// - parameter pattern:    The patterns whose subpatterns should be matched
    /// - parameter bounds:     The range in which the matching should occur.
    ///
    /// - returns:  The result set containing the lexical scope names with range
    ///             information or nil if aborted. May exceed range.
    private func matchSubpatternsOfPattern(_ pattern: Pattern, inRange bounds: NSRange) -> ResultSet? {
        let stop = bounds.location + bounds.length
        assert((string as NSString).length >= stop)
        var lineStart = bounds.location
        var lineEnd = bounds.location
        let result = ResultSet(startingRange: NSRange(location: bounds.location, length: 0))

        while lineEnd < stop {
            (string as NSString).getLineStart(nil, end: &lineEnd, contentsEnd: nil, for: NSMakeRange(lineEnd, 0))
            var range = NSRange(location: lineStart, length: lineEnd - lineStart)

            while range.length > 0 {
                if aborted { return nil }

                let bestMatchForMiddle = findMatchFromPatterns(pattern.subpatterns, inRange: range)

                if pattern.end != nil {
                    let endMatchResult = self.matchExpression(pattern.end!, inRange: range, captures: pattern.endCaptures)
                    if endMatchResult != nil && (bestMatchForMiddle == nil || bestMatchForMiddle != nil &&
                        (!pattern.applyEndPatternLast && endMatchResult!.range.location <= bestMatchForMiddle!.match.range.location || endMatchResult!.range.location < bestMatchForMiddle!.match.range.location)) {
                        result.addResults(endMatchResult!)
                        return result
                    }
                }

                if bestMatchForMiddle != nil {
                    let resultForMiddle: ResultSet?
                    if bestMatchForMiddle!.pattern.match != nil {
                        resultForMiddle = bestMatchForMiddle!.match
                    } else {
                        resultForMiddle = matchAfterBeginOfPattern(bestMatchForMiddle!.pattern, beginResults: bestMatchForMiddle!.match, inRange: range)
                    }

                    if resultForMiddle == nil || resultForMiddle!.range.length == 0 {
                        break
                    }

                    result.addResults(resultForMiddle!)
                    let newStart = NSMaxRange(resultForMiddle!.range)
                    range = NSRange(location: newStart, length: max(0, range.length - (newStart - range.location)))
                    lineEnd = max(lineEnd, newStart)
                } else {
                    break
                }
            }

            lineStart = lineEnd
        }

        result.extendWithRange(bounds)
        return result
    }

    /// Helper method that iterates over the given patterns and tries to match
    /// them. Returns the matched pattern with the highest priority
    /// (first criterion: matched sooner, second: higher up the list).
    ///
    /// - parameter patterns:   The patterns that should be matched
    /// - parameter range:      The range in which the matching should happen.
    ///
    /// - returns:  The results. nil if nothing could be matched and an empty
    ///             set if something could be matched but it doesn't have any
    ///             information associated with the match. The results range may
    ///             exceed the passed in range.
    private func findMatchFromPatterns(_ patterns: [Pattern], inRange bounds: NSRange) -> (pattern: Pattern, match: ResultSet)? {
        var interestingBounds = bounds
        var bestResult: (pattern: Pattern, match: ResultSet)?
        for pattern in patterns {
            let currentMatch = self.firstMatchOfPattern(pattern, inRange: bounds)
            if currentMatch?.match.range.location == bounds.location {
                return currentMatch
            } else if currentMatch != nil && (bestResult == nil || currentMatch != nil && currentMatch!.match.range.location < bestResult!.match.range.location) {
                bestResult = currentMatch
                interestingBounds.length = currentMatch!.match.range.location - interestingBounds.location
            }
        }
        return bestResult
    }

    /// Matches a single pattern in the string in the given range
    ///
    /// - returns: The result of the match. Nil if unsuccessful
    private func firstMatchOfPattern(_ pattern: Pattern, inRange bounds: NSRange) -> (pattern: Pattern, match: ResultSet)? {
        if let match = pattern.match {
            if let resultSet = matchExpression(match, inRange: bounds, captures: pattern.captures, baseSelector: pattern.name) {
                if resultSet.range.length != 0 {
                    return (pattern, resultSet)
                }
            }
        } else if let begin = pattern.begin {
            if let beginResults = matchExpression(begin, inRange: bounds, captures: pattern.beginCaptures) {
                return (pattern, beginResults)
            }
        } else if pattern.subpatterns.count >= 1 {
            return findMatchFromPatterns(pattern.subpatterns, inRange: bounds)
        }
        return nil
    }

    // Implementation note:
    // The order in which the beginning middle and end are added to the final
    // result matters.

    /// Matches the middle and end of the given pattern
    ///
    /// - parameter pattern:    The pattern whose subpatterns and end pattern
    ///                         has to be matched
    /// - parameter begin:      The match result of the beginning
    /// - parameter range:      The range in which to perform the match
    /// - returns:  The result of matching the given pattern or nil on abortion.
    ///             It's range may exceed the passed in range.
    private func matchAfterBeginOfPattern(_ pattern: Pattern, beginResults begin: ResultSet, inRange bounds: NSRange) -> ResultSet? {
            let newLocation = NSMaxRange(begin.range)
            guard let endResults = matchSubpatternsOfPattern(pattern, inRange: NSRange(location: newLocation, length: (string as NSString).length - newLocation)) else {
                return nil
            }

            let result = ResultSet(startingRange: endResults.range)
            if pattern.name != nil {
                result.addResult(Result(identifier: pattern.name!, range: NSUnionRange(begin.range, endResults.range)))
            }
            result.addResult(Scope(identifier: pattern.name ?? "", range: NSRange(location: begin.range.location + begin.range.length, length: NSUnionRange(begin.range, endResults.range).length - begin.range.length), attribute: pattern))
            result.addResults(begin)
            result.addResults(endResults)
            return result
    }

    /// Matches a given regular expression in a String and returns range
    /// information for the captures
    ///
    /// - parameter expression:     The regular expression to match
    /// - parameter range:          The range to which to restrict the match
    /// - parameter captures:       A collection of captures that can be used to
    ///                             add extra information to parts of the match.
    /// - parameter baseSelector:   String to associate with the entire range of
    ///                             the match
    ///
    /// - returns:  The set containing the results. May be nil if the expression
    ///             could not match any part of the string. It may also be empty
    ///             and only contain range information to show what it matched.
    private func matchExpression(_ regularExpression: NSRegularExpression, inRange bounds: NSRange, captures: CaptureCollection?, baseSelector: String? = nil) -> ResultSet? {
        guard let result = regularExpression.firstMatch(in: string, options: [.withTransparentBounds], range: bounds) else {
            return nil
        }

        let resultSet = ResultSet(startingRange: result.range)
        if baseSelector != nil {
            resultSet.addResult(Result(identifier: baseSelector!, range: result.range))
        }

        if let captures = captures {
            for index in captures.captureIndexes {
                if result.numberOfRanges <= Int(index) {
                    print("Attention unexpected capture (\(index) to \(result.numberOfRanges)): \(regularExpression.pattern)")
                    continue
                }
                let range = result.rangeAt(Int(index))
                if range.location == NSNotFound {
                    continue
                }

                if let scope = captures[index]?.name {
                    resultSet.addResult(Result(identifier: scope, range: range))
                }
            }
        }

        return resultSet
    }

    /// Uses the callback to communicate the result of the parsing pass back
    /// to the caller of parse.
    ///
    /// - parameter results:        The results of the parsing pass
    /// - parameter scopesString:   The place to store the scopes
    /// - parameter callback:       The method to call on every successful match
    private func applyResults(_ results: ResultSet, storingInScopesString scopesString: inout ScopedString, callback: Callback) {
        callback(Language.globalScope, results.range)
        for result in results.results where result.range.length > 0 {
            if result.attribute != nil {
                scopesString.addScopeAtTop(result as Scope)
            } else if result.patternIdentifier != "" {
                callback(result.patternIdentifier, result.range)
            }
        }
    }
}
