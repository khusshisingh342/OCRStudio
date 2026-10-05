//
//  ComplianceEngine.swift
//  OCRStudio
//
//  Created by Chitraksh Sharna on 05/10/26.
//

import Foundation
import SwiftUI

// ==========================================
// 1. COMPLIANCE RULE MODELS
// ==========================================
enum ComplianceStatus {
    case passed
    case failed
    case warning
}

struct ComplianceRule: Identifiable {
    let id = UUID()
    let fieldName: String
    let description: String
    let pattern: String // Regex pattern to check
    let isMandatory: Bool
}

struct RuleResult: Identifiable {
    let id = UUID()
    let rule: ComplianceRule
    let isFound: Bool
    let matchedText: String?
}

// ==========================================
// 2. RULE-BASED VERIFICATION ENGINE
// ==========================================
class ComplianceEngine {
    
    // Default Rule Set (e.g., Packaged Commodity Rules)
    private let rules: [ComplianceRule] = [
        ComplianceRule(
            fieldName: "Net Quantity",
            description: "Must state weight/volume (e.g., 500g, 1L, 250 ml)",
            pattern: "(?i)\\b(net\\s*qty|net\\s*weight|net\\s*vol|quantity|qty)[:\\s]*\\d+\\s*(g|kg|ml|l|ltr|grams|litres)\\b|\\b\\d+\\s*(g|kg|ml|l|ltr)\\b",
            isMandatory: true
        ),
        ComplianceRule(
            fieldName: "Maximum Retail Price (MRP)",
            description: "Must state MRP inclusive of all taxes",
            pattern: "(?i)\\b(mrp|max\\.?\\s*retail\\s*price)[:\\s]*₹?\\s*\\d+(\\.\\d{1,2})?",
            isMandatory: true
        ),
        ComplianceRule(
            fieldName: "Date of Manufacture / Packing",
            description: "Must disclose Mfg or Pkd date",
            pattern: "(?i)\\b(mfg|pkd|packed|manufactured|mfg\\s*date)[:\\s]*(\\d{2}[/\\.-]\\d{2}[/\\.-]\\d{2,4}|[a-zA-Z]{3}\\s*\\d{4})",
            isMandatory: true
        ),
        ComplianceRule(
            fieldName: "Consumer Care Contact",
            description: "Must include helpline email or telephone number",
            pattern: "(?i)(\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b|\\b(customer\\s*care|helpline|phone|toll\\s*free)[:\\s]*[0-9\\+\\-\\s]{8,})",
            isMandatory: true
        ),
        ComplianceRule(
            fieldName: "Country of Origin",
            description: "Must disclose manufacturing origin",
            pattern: "(?i)\\b(country\\s*of\\s*origin|made\\s*in)[:\\s]*[a-zA-Z]+",
            isMandatory: false
        )
    ]
    
    func evaluate(extractedText: String) -> (results: [RuleResult], overallStatus: ComplianceStatus, scorePercentage: Int) {
        var results: [RuleResult] = []
        var passedMandatoryCount = 0
        var totalMandatoryCount = 0
        
        for rule in rules {
            if rule.isMandatory { totalMandatoryCount += 1 }
            
            let matchedText = findMatch(pattern: rule.pattern, in: extractedText)
            let isFound = matchedText != nil
            
            if isFound && rule.isMandatory {
                passedMandatoryCount += 1
            }
            
            results.append(RuleResult(rule: rule, isFound: isFound, matchedText: matchedText))
        }
        
        let score = totalMandatoryCount > 0 ? Int((Double(passedMandatoryCount) / Double(totalMandatoryCount)) * 100) : 0
        
        let overallStatus: ComplianceStatus
        if score == 100 {
            overallStatus = .passed
        } else if score >= 50 {
            overallStatus = .warning
        } else {
            overallStatus = .failed
        }
        
        return (results, overallStatus, score)
    }
    
    private func findMatch(pattern: String, in text: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = text as NSString
            let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let firstMatch = results.first {
                return nsString.substring(with: firstMatch.range)
            }
        } catch {
            print("Regex compilation error: \(error.localizedDescription)")
        }
        return nil
    }
}

// ==========================================
// 3. COMPLIANCE REPORT UI COMPONENT
// ==========================================
struct ComplianceReportView: View {
    let textToAnalyze: String
    
    private var engine = ComplianceEngine()
    
    var body: some View {
        let (results, overallStatus, score) = engine.evaluate(extractedText: textToAnalyze)
        
        VStack(alignment: .leading, spacing: 14) {
            // Header & Score Banner
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Compliance Report")
                        .font(.headline)
                        .foregroundColor(AppTheme.textDark)
                    Text("Rule-based declaration verification")
                        .font(.caption)
                        .foregroundColor(AppTheme.textMuted)
                }
                Spacer()
                
                // Overall Badge
                HStack(spacing: 6) {
                    Image(systemName: overallStatusIcon(overallStatus))
                    Text("\(score)%")
                        .font(.subheadline).bold()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(overallStatusColor(overallStatus).opacity(0.15))
                .foregroundColor(overallStatusColor(overallStatus))
                .cornerRadius(8)
            }
            
            Divider()
            
            // Rules Checklist
            VStack(spacing: 10) {
                ForEach(results) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: item.isFound ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(item.isFound ? .green : (item.rule.isMandatory ? .red : .orange))
                            .font(.system(size: 18))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(item.rule.fieldName)
                                    .font(.subheadline).bold()
                                    .foregroundColor(AppTheme.textDark)
                                
                                if item.rule.isMandatory {
                                    Text("REQUIRED")
                                        .font(.system(size: 9, weight: .heavy))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(4)
                                }
                            }
                            
                            if let match = item.matchedText {
                                Text("Found: \"\(match)\"")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text(item.rule.description)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textMuted)
                            }
                        }
                        Spacer()
                    }
                    .padding(8)
                    .background(AppTheme.secondaryBlue.opacity(0.3))
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.primaryBlue.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func overallStatusColor(_ status: ComplianceStatus) -> Color {
        switch status {
        case .passed: return .green
        case .warning: return .orange
        case .failed: return .red
        }
    }
    
    private func overallStatusIcon(_ status: ComplianceStatus) -> String {
        switch status {
        case .passed: return "checkmark.seal.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .failed: return "xmark.seal.fill"
        }
    }
}
