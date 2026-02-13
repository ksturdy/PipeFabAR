//
//  SystemType.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import Foundation
import SwiftUI

/// Global system types shared across all projects
enum SystemType: String, Codable, CaseIterable {
    case hotWater = "Hot Water"
    case coldWater = "Cold Water"
    case chilledWater = "Chilled Water"
    case gas = "Gas"
    case hvac = "HVAC"
    case drain = "Drain"
    case vent = "Vent"
    case steam = "Steam"
    case compressedAir = "Compressed Air"
    case custom = "Custom"

    /// Hex color for visual distinction
    var color: String {
        switch self {
        case .hotWater: return "#FF3B30" // Red
        case .coldWater: return "#007AFF" // Blue
        case .chilledWater: return "#5AC8FA" // Light Blue
        case .gas: return "#FFCC00" // Yellow
        case .hvac: return "#FF9500" // Orange
        case .drain: return "#8E8E93" // Gray
        case .vent: return "#C7C7CC" // Light Gray
        case .steam: return "#FF2D55" // Pink
        case .compressedAir: return "#5856D6" // Purple
        case .custom: return "#34C759" // Green
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .hotWater: return "flame.fill"
        case .coldWater: return "drop.fill"
        case .chilledWater: return "snowflake"
        case .gas: return "fuelpump.fill"
        case .hvac: return "fan.fill"
        case .drain: return "arrow.down.circle.fill"
        case .vent: return "wind"
        case .steam: return "cloud.fill"
        case .compressedAir: return "tornado"
        case .custom: return "wrench.and.screwdriver.fill"
        }
    }

    /// SwiftUI Color from hex
    var swiftUIColor: Color {
        Color(hex: color) ?? .gray
    }
}
