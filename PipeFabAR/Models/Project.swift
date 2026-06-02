//
//  Project.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import Foundation
import SwiftData

/// Top-level organizational unit for pipe routing work
@Model
final class Project {
    var id: UUID
    var name: String
    var jobNumber: String
    var createdDate: Date
    var modifiedDate: Date
    var color: String // Hex color for visual distinction

    // Naming configuration
    var spoolNamingTemplate: String // e.g., "{jobNumber}-{packageNumber}-{spoolNumber}"
    var nextSpoolNumber: Int // Auto-increment counter

    // Pipe specification (default for this project)
    @Relationship(deleteRule: .nullify) var defaultPipeSpecification: PipeSpecification?

    // Relationships
    @Relationship(deleteRule: .cascade) var workPackages: [WorkPackage]
    @Relationship(deleteRule: .cascade) var spools: [Spool] // Unassigned pool

    init(
        id: UUID = UUID(),
        name: String,
        jobNumber: String,
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        color: String = "#007AFF", // Default iOS blue
        spoolNamingTemplate: String = "{jobNumber}-{packageNumber}-{spoolNumber}",
        nextSpoolNumber: Int = 1,
        defaultPipeSpecification: PipeSpecification? = nil,
        workPackages: [WorkPackage] = [],
        spools: [Spool] = []
    ) {
        self.id = id
        self.name = name
        self.jobNumber = jobNumber
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.color = color
        self.spoolNamingTemplate = spoolNamingTemplate
        self.nextSpoolNumber = nextSpoolNumber
        self.defaultPipeSpecification = defaultPipeSpecification
        self.workPackages = workPackages
        self.spools = spools
    }

    /// Total number of spools (assigned + unassigned)
    var totalSpoolCount: Int {
        let assignedCount = workPackages.reduce(0) { $0 + $1.assignedSpools.count }
        return assignedCount + spools.count
    }

    /// Total number of work packages
    var workPackageCount: Int {
        workPackages.count
    }
}
