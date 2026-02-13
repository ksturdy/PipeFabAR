//
//  SpoolNamingService.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import Foundation

/// Service for generating spool names from templates
class SpoolNamingService {
    /// Generate spool name from project template
    /// - Parameters:
    ///   - project: The project containing the naming template
    ///   - workPackage: Optional work package (for package number)
    /// - Returns: Generated spool name (e.g., "2026-001-005")
    static func generateName(
        project: Project,
        workPackage: WorkPackage? = nil
    ) -> String {
        let template = project.spoolNamingTemplate
        let spoolNum = project.nextSpoolNumber

        var name = template
            .replacingOccurrences(of: "{jobNumber}", with: project.jobNumber)
            .replacingOccurrences(of: "{spoolNumber}", with: String(format: "%03d", spoolNum))

        if let pkg = workPackage {
            name = name.replacingOccurrences(of: "{packageNumber}", with: pkg.packageNumber)
        } else {
            // If no package, use "000" as placeholder
            name = name.replacingOccurrences(of: "{packageNumber}", with: "000")
        }

        return name
    }

    /// Default naming templates for user selection
    static let templates: [String] = [
        "{jobNumber}-{packageNumber}-{spoolNumber}",
        "{jobNumber}_{packageNumber}_{spoolNumber}",
        "JOB{jobNumber}-PKG{packageNumber}-{spoolNumber}",
        "{packageNumber}-{spoolNumber}",
        "SPOOL-{spoolNumber}"
    ]

    /// Validate that a template has required placeholders
    /// - Parameter template: The template string to validate
    /// - Returns: True if valid (must contain {spoolNumber})
    static func validate(_ template: String) -> Bool {
        return template.contains("{spoolNumber}")
    }

    /// Extract placeholder tokens from template for UI display
    /// - Parameter template: The template string
    /// - Returns: Array of placeholder names (e.g., ["jobNumber", "packageNumber", "spoolNumber"])
    static func extractPlaceholders(from template: String) -> [String] {
        let pattern = "\\{(.*?)\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let nsString = template as NSString
        let matches = regex.matches(in: template, range: NSRange(location: 0, length: nsString.length))

        return matches.compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            let range = match.range(at: 1)
            return nsString.substring(with: range)
        }
    }

    /// Generate a preview of the template with example data
    /// - Parameters:
    ///   - template: The template string
    ///   - jobNumber: Example job number (default: "2026")
    ///   - packageNumber: Example package number (default: "001")
    ///   - spoolNumber: Example spool number (default: 1)
    /// - Returns: Preview string (e.g., "2026-001-001")
    static func preview(
        template: String,
        jobNumber: String = "2026",
        packageNumber: String = "001",
        spoolNumber: Int = 1
    ) -> String {
        return template
            .replacingOccurrences(of: "{jobNumber}", with: jobNumber)
            .replacingOccurrences(of: "{packageNumber}", with: packageNumber)
            .replacingOccurrences(of: "{spoolNumber}", with: String(format: "%03d", spoolNumber))
    }
}
