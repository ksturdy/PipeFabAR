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
    var id: UUID = UUID()
    var specDescription: String = ""
    var abbreviation: String = ""
    var sortOrder: Int = 0
    var isDefault: Bool = false

    // Inverse back-references required for CloudKit
    @Relationship(deleteRule: .nullify) var projectsUsingAsDefault: [Project]?
    @Relationship(deleteRule: .nullify) var spoolOverrides: [Spool]?
    @Relationship(deleteRule: .nullify) var workPackageOverrides: [WorkPackage]?

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

    var displayName: String {
        "\(specDescription) (\(abbreviation))"
    }
}
