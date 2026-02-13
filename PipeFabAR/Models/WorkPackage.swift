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
    @Attribute(.unique) var id: UUID
    var name: String
    var packageNumber: String
    var createdDate: Date
    var dueDate: Date?
    var status: String // "Not Started", "In Progress", "Review", "Completed"
    var notes: String

    // Pipe specification override (nil = inherit from project)
    @Relationship(deleteRule: .nullify) var pipeSpecificationOverride: PipeSpecification?

    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Project.workPackages) var project: Project?
    @Relationship(deleteRule: .nullify) var assignedSpools: [Spool]

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
        assignedSpools: [Spool] = []
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

    /// Effective pipe specification (override or inherited from project)
    var effectivePipeSpecification: PipeSpecification? {
        pipeSpecificationOverride ?? project?.defaultPipeSpecification
    }

    /// Number of spools assigned to this work package
    var spoolCount: Int {
        assignedSpools.count
    }

    /// Status enum for type-safe access
    enum Status: String, CaseIterable {
        case notStarted = "Not Started"
        case inProgress = "In Progress"
        case review = "Review"
        case completed = "Completed"

        var color: String {
            switch self {
            case .notStarted: return "#8E8E93" // Gray
            case .inProgress: return "#FF9500" // Orange
            case .review: return "#007AFF" // Blue
            case .completed: return "#34C759" // Green
            }
        }
    }
}
