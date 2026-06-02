//
//  PipeSpecification.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import Foundation
import SwiftData

/// Pipe material and schedule specification
@Model
final class PipeSpecification {
    var id: UUID
    var specDescription: String // e.g., "Carbon Steel Schedule 40"
    var abbreviation: String    // e.g., "CS SCH 40"
    var sortOrder: Int          // For custom ordering
    var isDefault: Bool         // Whether this is the default spec for new projects

    init(
        id: UUID = UUID(),
        specDescription: String,
        abbreviation: String,
        sortOrder: Int = 0,
        isDefault: Bool = false
    ) {
        self.id = id
        self.specDescription = specDescription
        self.abbreviation = abbreviation
        self.sortOrder = sortOrder
        self.isDefault = isDefault
    }

    /// Display name combining description and abbreviation
    var displayName: String {
        "\(specDescription) (\(abbreviation))"
    }
}
