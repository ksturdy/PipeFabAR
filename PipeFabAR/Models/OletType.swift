//
//  OletType.swift
//  PipeFabAR
//
//  Created by Claude on 2026-02-10.
//

import Foundation

/// Types of outlet fittings that can be added to pipe segments
enum OletType: String, Codable, CaseIterable {
    case weldolet = "Weldolet"
    case threadolet = "Threadolet"
    case sockolet = "Sockolet"
    case latrolet = "Latrolet"
    case elbolet = "Elbolet"

    var symbol: String {
        switch self {
        case .weldolet: return "⊚"
        case .threadolet: return "⊗"
        case .sockolet: return "◉"
        case .latrolet: return "⊕"
        case .elbolet: return "⊙"
        }
    }

    var shortName: String {
        switch self {
        case .weldolet: return "WO"
        case .threadolet: return "TO"
        case .sockolet: return "SO"
        case .latrolet: return "LO"
        case .elbolet: return "EO"
        }
    }
}

/// Represents an outlet fitting on a pipe segment
struct Olet: Identifiable, Codable {
    let id: UUID
    var type: OletType
    var position: CGFloat  // Position along segment (0.0 to 1.0, where 0.5 is midpoint)
    var orientation: CGFloat  // Branch direction angle in degrees (0-360°)
    var size: PipeSize  // Outlet size
    var dimensionLabelOffset: CGSize?  // Custom offset for the dimension label

    init(
        id: UUID = UUID(),
        type: OletType = .weldolet,
        position: CGFloat = 0.5,
        orientation: CGFloat = 90,
        size: PipeSize = .none,
        dimensionLabelOffset: CGSize? = nil
    ) {
        self.id = id
        self.position = position
        self.orientation = orientation
        self.type = type
        self.size = size
        self.dimensionLabelOffset = dimensionLabelOffset
    }
}
