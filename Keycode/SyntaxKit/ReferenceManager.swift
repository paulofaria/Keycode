//
//  Patterns.swift
//  SyntaxKit
//
//  A utility class to facilitate the creation of pattern arrays.
//  It works it the following fashion: First all the pattern arrays should be 
//  created with patternsForArray:inRepository:caller:. Then
//  resolveReferencesWithRepository:inLanguage: has to be called to resolve all
//  the references in the passed out patterns. So first lots of calls to 
//  patternsForArray and then one call to resolveReferences to validate the
//  patterns by resolving all references.
//
//  Created by Alexander Hedges on 09/01/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

import Foundation

class ReferenceManager {
    
    // MARK: - Properties
    
    private var includes: [Include] = []
    private weak var bundleManager: BundleManager?
    
    
    // MARK: - Init
    
    init(bundleManager: BundleManager) {
        self.bundleManager = bundleManager
    }
    
    
    // MARK: - Pattern Creation and Resolution
    
    func patternsForArray(_ patterns: [[NSObject: AnyObject]], inRepository repository: Repository?, caller: Pattern?) -> [Pattern] {
        var results: [Pattern] = []
        for rawPattern in patterns {
            if let include = (rawPattern as NSDictionary)["include"] as? String {
                let reference = Include(reference: include, inRepository: repository, parent: caller, bundleManager: bundleManager!)
                self.includes.append(reference)
                results.append(reference)
            } else if let pattern = Pattern(dictionary: rawPattern, parent: caller, withRepository: repository, withReferenceManager: self) {
                results.append(pattern)
            }
        }
        return results
    }
    
    func resolveInternalReferences(_ repository: Repository, inLanguage language: Language) {
        for include in includes {
            include.resolveInternalReference(repository, inLanguage: language)
        }
    }
    
    class func resolveExternalReferencesBetweenLanguages(_ languages: [Language], basename: String) {
        var otherLanguages: [String: Language] = [:]
        for language in languages {
            otherLanguages[language.scopeName] = language
        }
        for language in languages {
            let includes = language.referenceManager.includes
            for include in includes {
                include.resolveExternalReference(language, inLanguages: otherLanguages, baseName: basename)
            }
        }
    }
}
