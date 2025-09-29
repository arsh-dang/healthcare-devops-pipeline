#!/usr/bin/env groovy

// Simple Jenkinsfile syntax validator
// This script checks basic Groovy syntax without Jenkins-specific constructs

import groovy.transform.CompileStatic

@CompileStatic
class JenkinsfileValidator {
    
    static void main(String[] args) {
        def jenkinsfilePath = args.length > 0 ? args[0] : 'Jenkinsfile'
        
        println "Validating Jenkinsfile syntax: $jenkinsfilePath"
        
        try {
            // Read the Jenkinsfile
            def file = new File(jenkinsfilePath)
            if (!file.exists()) {
                println "ERROR: Jenkinsfile not found at $jenkinsfilePath"
                System.exit(1)
            }
            
            def content = file.text
            
            // Basic syntax checks
            validateBraces(content)
            validateParentheses(content)
            validateQuotes(content)
            
            println "✅ Basic Groovy syntax validation passed!"
            println "Note: Jenkins-specific syntax (node, stage, etc.) requires Jenkins runtime"
            
        } catch (Exception e) {
            println "❌ Validation failed: ${e.message}"
            System.exit(1)
        }
    }
    
    static void validateBraces(String content) {
        def openBraces = content.count('{')
        def closeBraces = content.count('}')
        
        if (openBraces != closeBraces) {
            throw new Exception("Brace mismatch: $openBraces opening braces, $closeBraces closing braces")
        }
        
        println "✅ Braces balanced: $openBraces pairs"
    }
    
    static void validateParentheses(String content) {
        def openParens = content.count('(')
        def closeParens = content.count(')')
        
        if (openParens != closeParens) {
            throw new Exception("Parentheses mismatch: $openParens opening, $closeParens closing")
        }
        
        println "✅ Parentheses balanced: $openParens pairs"
    }
    
    static void validateQuotes(String content) {
        def singleQuotes = content.count("'")
        def doubleQuotes = content.count('"')
        
        if (singleQuotes % 2 != 0) {
            throw new Exception("Unmatched single quotes: $singleQuotes found")
        }
        
        if (doubleQuotes % 2 != 0) {
            throw new Exception("Unmatched double quotes: $doubleQuotes found")
        }
        
        println "✅ Quotes balanced: $singleQuotes single quotes, $doubleQuotes double quotes"
    }
}
