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
    var id: UUID = UUID()
    var name: String = ""
    var jobNumber: String = ""
    var createdDate: Date = Date()
    var modifiedDate: Date = Date()
    var color: String = "#007AFF"
    var spoolNamingTemplate: String = "{jobNumber}-{packageNumber}-{spoolNumber}"
    var nextSpoolNumber: Int = 1

    @Relationship(deleteRule: .nullify, inverse: \PipeSpecification.projectsUsingAsDefault) var defaultPipeSpecification: PipeSpecification?
    @Relationship(deleteRule: .cascade) var workPackages: [WorkPackage]?
    @Relationship(deleteRule: .cascade) var spools: [Spool]?

    init(
        id: UUID = UUID(),
        name: String,
        jobNumber: String,
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        color: String = "#007AFF",
        spoolNamingTemplate: String = "{jobNumber}-{packageNumber}-{spoolNumber}",
        nextSpoolNumber: Int = 1,
        defaultPipeSpecification: PipeSpecification? = nil,
        workPackages: [WorkPackage]? = [],
        spools: [Spool]? = []
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

    var totalSpoolCount: Int {
        let assignedCount = (workPackages ?? []).reduce(0) { $0 + ($1.assignedSpools ?? []).count }
        return assignedCount + (spools ?? []).count
    }

    var workPackageCount: Int {
        (workPackages ?? []).count
    }
}
