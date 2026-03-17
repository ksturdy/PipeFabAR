//
//  CustomDimensionOverride.swift
//  PipeFabAR
//
//  Created by Claude on 2026-02-15.
//  Database storage for custom/non-standard pipe and fitting dimensions
//

import Foundation
import SwiftData

/// Custom dimension override for non-standard components
/// This allows users to store custom dimensions for specialty fittings or valves
@Model
final class CustomDimensionOverride {
    @Attribute(.unique) var id: UUID
    var name: String  // e.g., "Special 4\" Ball Valve - Brand XYZ"
    var componentType: String  // "pipe", "fitting", "valve", "flange"
    var pipeSize: String  // PipeSize raw value
    var fittingType: String?  // FittingType raw value (if applicable)
    var valveType: String?  // ValveType raw value (if applicable)

    // Dimensional overrides (nil = use standard)
    var outerDiameter: Double?
    var wallThickness: Double?
    var centerToFace: Double?
    var faceToFace: Double?
    var flangeOuterDiameter: Double?
    var flangeBoltCircle: Double?
    var flangeThickness: Double?
    var bodyWidth: Double?
    var bodyHeight: Double?

    // Metadata
    var notes: String?
    var createdDate: Date
    var modifiedDate: Date

    // Relationships
    @Relationship(deleteRule: .nullify) var project: Project?  // Project-specific overrides

    init(
        id: UUID = UUID(),
        name: String,
        componentType: String,
        pipeSize: String,
        fittingType: String? = nil,
        valveType: String? = nil,
        outerDiameter: Double? = nil,
        wallThickness: Double? = nil,
        centerToFace: Double? = nil,
        faceToFace: Double? = nil,
        flangeOuterDiameter: Double? = nil,
        flangeBoltCircle: Double? = nil,
        flangeThickness: Double? = nil,
        bodyWidth: Double? = nil,
        bodyHeight: Double? = nil,
        notes: String? = nil,
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        project: Project? = nil
    ) {
        self.id = id
        self.name = name
        self.componentType = componentType
        self.pipeSize = pipeSize
        self.fittingType = fittingType
        self.valveType = valveType
        self.outerDiameter = outerDiameter
        self.wallThickness = wallThickness
        self.centerToFace = centerToFace
        self.faceToFace = faceToFace
        self.flangeOuterDiameter = flangeOuterDiameter
        self.flangeBoltCircle = flangeBoltCircle
        self.flangeThickness = flangeThickness
        self.bodyWidth = bodyWidth
        self.bodyHeight = bodyHeight
        self.notes = notes
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.project = project
    }
}

/// Component type enumeration for custom overrides
enum ComponentType: String, CaseIterable {
    case pipe = "Pipe"
    case fitting = "Fitting"
    case valve = "Valve"
    case flange = "Flange"
    case specialty = "Specialty"
}

/// Extension to help lookup custom dimensions
extension CustomDimensionOverride {
    /// Check if this override matches the given criteria
    func matches(componentType: String, pipeSize: PipeSize, fittingType: FittingType? = nil, valveType: ValveType? = nil) -> Bool {
        guard self.componentType == componentType,
              self.pipeSize == pipeSize.rawValue else {
            return false
        }

        if let fType = fittingType {
            return self.fittingType == fType.rawValue
        }

        if let vType = valveType {
            return self.valveType == vType.rawValue
        }

        return true
    }
}
