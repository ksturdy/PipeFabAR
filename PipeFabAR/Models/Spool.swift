//
//  Spool.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import Foundation
import SwiftData

/// Individual pipe assembly containing drawing data
@Model
final class Spool {
    @Attribute(.unique) var id: UUID
    var name: String
    var systemType: String? // Reference to SystemType enum raw value
    var status: String // "Draft", "Ready", "Fabricated", "Installed"
    var createdDate: Date
    var modifiedDate: Date

    // Drawing data (encoded [PipePoint])
    var pipePointsData: Data
    var zoomScale: Double
    var panOffsetWidth: Double
    var panOffsetHeight: Double
    var thumbnailData: Data? // Cached preview image

    // Pipe specification override (nil = inherit from work package or project)
    @Relationship(deleteRule: .nullify) var pipeSpecificationOverride: PipeSpecification?

    // Relationships
    @Relationship(deleteRule: .nullify) var workPackage: WorkPackage?
    @Relationship(deleteRule: .nullify) var project: Project? // Parent project

    init(
        id: UUID = UUID(),
        name: String,
        systemType: String? = nil,
        status: String = "Draft",
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        pipePointsData: Data = Data(),
        zoomScale: Double = 1.0,
        panOffsetWidth: Double = 0.0,
        panOffsetHeight: Double = 0.0,
        thumbnailData: Data? = nil,
        pipeSpecificationOverride: PipeSpecification? = nil,
        workPackage: WorkPackage? = nil,
        project: Project? = nil
    ) {
        self.id = id
        self.name = name
        self.systemType = systemType
        self.status = status
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.pipePointsData = pipePointsData
        self.zoomScale = zoomScale
        self.panOffsetWidth = panOffsetWidth
        self.panOffsetHeight = panOffsetHeight
        self.thumbnailData = thumbnailData
        self.pipeSpecificationOverride = pipeSpecificationOverride
        self.workPackage = workPackage
        self.project = project
    }

    /// Effective pipe specification (override > work package > project)
    var effectivePipeSpecification: PipeSpecification? {
        pipeSpecificationOverride ?? workPackage?.effectivePipeSpecification ?? project?.defaultPipeSpecification
    }

    /// Decode pipe points from stored data
    var pipePoints: [PipePoint] {
        get {
            guard !pipePointsData.isEmpty,
                  let points = try? JSONDecoder().decode([PipePoint].self, from: pipePointsData) else {
                return []
            }
            return points
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                pipePointsData = encoded
            }
        }
    }

    /// Pan offset as CGSize for UI convenience
    var panOffset: CGSize {
        get {
            CGSize(width: panOffsetWidth, height: panOffsetHeight)
        }
        set {
            panOffsetWidth = newValue.width
            panOffsetHeight = newValue.height
        }
    }

    /// Status enum for type-safe access
    enum Status: String, CaseIterable {
        case draft = "Draft"
        case ready = "Ready for Fabrication"
        case fabricated = "Fabricated"
        case installed = "Installed"

        var color: String {
            switch self {
            case .draft: return "#8E8E93" // Gray
            case .ready: return "#34C759" // Green
            case .fabricated: return "#007AFF" // Blue
            case .installed: return "#5856D6" // Purple
            }
        }
    }
}
