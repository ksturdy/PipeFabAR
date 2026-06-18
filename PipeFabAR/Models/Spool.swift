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
    var id: UUID = UUID()
    var name: String = ""
    var systemType: String?
    var status: String = "Draft"
    var createdDate: Date = Date()
    var modifiedDate: Date = Date()
    var pipePointsData: Data = Data()
    var zoomScale: Double = 1.0
    var panOffsetWidth: Double = 0.0
    var panOffsetHeight: Double = 0.0
    var thumbnailData: Data?

    @Relationship(deleteRule: .nullify, inverse: \PipeSpecification.spoolOverrides) var pipeSpecificationOverride: PipeSpecification?
    @Relationship(deleteRule: .nullify, inverse: \WorkPackage.assignedSpools) var workPackage: WorkPackage?
    @Relationship(deleteRule: .nullify, inverse: \Project.spools) var project: Project?

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

    var effectivePipeSpecification: PipeSpecification? {
        pipeSpecificationOverride ?? workPackage?.effectivePipeSpecification ?? project?.defaultPipeSpecification
    }

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

    var panOffset: CGSize {
        get { CGSize(width: panOffsetWidth, height: panOffsetHeight) }
        set {
            panOffsetWidth = newValue.width
            panOffsetHeight = newValue.height
        }
    }

    enum Status: String, CaseIterable {
        case draft = "Draft"
        case ready = "Ready for Fabrication"
        case fabricated = "Fabricated"
        case installed = "Installed"

        var color: String {
            switch self {
            case .draft: return "#8E8E93"
            case .ready: return "#34C759"
            case .fabricated: return "#007AFF"
            case .installed: return "#5856D6"
            }
        }
    }
}
