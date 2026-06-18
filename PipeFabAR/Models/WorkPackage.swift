//
//  WorkPackage.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import Foundation
import SwiftData

/// Work breakdown structure for organizing spools
@Model
final class WorkPackage {
    var id: UUID = UUID()
    var name: String = ""
    var packageNumber: String = ""
    var createdDate: Date = Date()
    var dueDate: Date?
    var status: String = "Not Started"
    var notes: String = ""

    @Relationship(deleteRule: .nullify, inverse: \PipeSpecification.workPackageOverrides) var pipeSpecificationOverride: PipeSpecification?
    @Relationship(deleteRule: .nullify, inverse: \Project.workPackages) var project: Project?
    @Relationship(deleteRule: .nullify) var assignedSpools: [Spool]?

    init(
        id: UUID = UUID(),
        name: String,
        packageNumber: String,
        createdDate: Date = Date(),
        dueDate: Date? = nil,
        status: String = "Not Started",
        notes: String = "",
        pipeSpecificationOverride: PipeSpecification? = nil,
        project: Project? = nil,
        assignedSpools: [Spool]? = []
    ) {
        self.id = id
        self.name = name
        self.packageNumber = packageNumber
        self.createdDate = createdDate
        self.dueDate = dueDate
        self.status = status
        self.notes = notes
        self.pipeSpecificationOverride = pipeSpecificationOverride
        self.project = project
        self.assignedSpools = assignedSpools
    }

    var effectivePipeSpecification: PipeSpecification? {
        pipeSpecificationOverride ?? project?.defaultPipeSpecification
    }

    var spoolCount: Int {
        (assignedSpools ?? []).count
    }

    enum Status: String, CaseIterable {
        case notStarted = "Not Started"
        case inProgress = "In Progress"
        case review = "Review"
        case completed = "Completed"

        var color: String {
            switch self {
            case .notStarted: return "#8E8E93"
            case .inProgress: return "#FF9500"
            case .review: return "#007AFF"
            case .completed: return "#34C759"
            }
        }
    }
}
