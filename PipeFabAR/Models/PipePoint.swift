//
//  PipePoint.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import Foundation
import CoreGraphics

/// Represents a single point in a pipe drawing with its attributes
struct PipePoint: Identifiable, Codable {
    let id: UUID
    var position: CGPoint
    var fittingType: FittingType
    var pipeSize: PipeSize
    var measurementType: String?  // "F-C", "E-C", or "C-C"

    // Tee fitting orientation and branch support
    var fittingOrientation: CGFloat?  // Branch direction angle in degrees (0-360°)
    var branchParentId: UUID?  // Points to parent tee's UUID if this is a branch point

    // Custom label offsets (nil = use default position)
    var dimensionLabelOffset: CGSize?
    var sizeLabelOffset: CGSize?
    var bubbleLabelOffset: CGSize?
    var segmentBubbleOffset: CGSize?  // Offset for pipe segment letter bubble (A, B, C...)

    // Branch-specific offsets (used for the branch segment coming INTO this point from parent tee)
    var branchDimensionLabelOffset: CGSize?
    var branchSizeLabelOffset: CGSize?
    var branchSegmentBubbleOffset: CGSize?

    // O'lets on the segment starting from this point
    var olets: [Olet]

    init(
        id: UUID = UUID(),
        position: CGPoint,
        fittingType: FittingType = .none,
        pipeSize: PipeSize = .none,
        measurementType: String? = nil,
        fittingOrientation: CGFloat? = nil,
        branchParentId: UUID? = nil,
        dimensionLabelOffset: CGSize? = nil,
        sizeLabelOffset: CGSize? = nil,
        bubbleLabelOffset: CGSize? = nil,
        segmentBubbleOffset: CGSize? = nil,
        branchDimensionLabelOffset: CGSize? = nil,
        branchSizeLabelOffset: CGSize? = nil,
        branchSegmentBubbleOffset: CGSize? = nil,
        olets: [Olet] = []
    ) {
        self.id = id
        self.position = position
        self.fittingType = fittingType
        self.pipeSize = pipeSize
        self.measurementType = measurementType
        self.fittingOrientation = fittingOrientation
        self.branchParentId = branchParentId
        self.dimensionLabelOffset = dimensionLabelOffset
        self.sizeLabelOffset = sizeLabelOffset
        self.bubbleLabelOffset = bubbleLabelOffset
        self.segmentBubbleOffset = segmentBubbleOffset
        self.branchDimensionLabelOffset = branchDimensionLabelOffset
        self.branchSizeLabelOffset = branchSizeLabelOffset
        self.branchSegmentBubbleOffset = branchSegmentBubbleOffset
        self.olets = olets
    }

    // Custom Codable implementation for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        position = try container.decode(CGPoint.self, forKey: .position)
        fittingType = try container.decode(FittingType.self, forKey: .fittingType)
        pipeSize = try container.decode(PipeSize.self, forKey: .pipeSize)
        measurementType = try container.decodeIfPresent(String.self, forKey: .measurementType)
        fittingOrientation = try container.decodeIfPresent(CGFloat.self, forKey: .fittingOrientation)
        branchParentId = try container.decodeIfPresent(UUID.self, forKey: .branchParentId)
        dimensionLabelOffset = try container.decodeIfPresent(CGSize.self, forKey: .dimensionLabelOffset)
        sizeLabelOffset = try container.decodeIfPresent(CGSize.self, forKey: .sizeLabelOffset)
        bubbleLabelOffset = try container.decodeIfPresent(CGSize.self, forKey: .bubbleLabelOffset)
        segmentBubbleOffset = try container.decodeIfPresent(CGSize.self, forKey: .segmentBubbleOffset)
        branchDimensionLabelOffset = try container.decodeIfPresent(CGSize.self, forKey: .branchDimensionLabelOffset)
        branchSizeLabelOffset = try container.decodeIfPresent(CGSize.self, forKey: .branchSizeLabelOffset)
        branchSegmentBubbleOffset = try container.decodeIfPresent(CGSize.self, forKey: .branchSegmentBubbleOffset)
        // Provide default empty array for backward compatibility with old saved spools
        olets = try container.decodeIfPresent([Olet].self, forKey: .olets) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case id, position, fittingType, pipeSize, measurementType
        case fittingOrientation, branchParentId
        case dimensionLabelOffset, sizeLabelOffset, bubbleLabelOffset, segmentBubbleOffset
        case branchDimensionLabelOffset, branchSizeLabelOffset, branchSegmentBubbleOffset
        case olets
    }
}

// Note: CGPoint and CGSize are already Codable in iOS 17+
