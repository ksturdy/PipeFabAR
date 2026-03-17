//
//  PipeDimensions.swift
//  PipeFabAR
//
//  Created by Claude on 2026-02-15.
//  ASME B36.10M - Standard Pipe Dimensions
//

import Foundation

/// Standard pipe dimensions per ASME B36.10M
extension PipeSize {
    /// Nominal pipe size in inches (for calculations)
    var nominalDiameter: Double {
        switch self {
        case .none: return 0
        case .half: return 0.5
        case .threeQuarter: return 0.75
        case .one: return 1.0
        case .oneAndQuarter: return 1.25
        case .oneAndHalf: return 1.5
        case .two: return 2.0
        case .twoAndHalf: return 2.5
        case .three: return 3.0
        case .four: return 4.0
        case .six: return 6.0
        case .eight: return 8.0
        case .ten: return 10.0
        case .twelve: return 12.0
        }
    }

    /// Outer diameter in inches per ASME B36.10M
    /// Note: OD is constant regardless of schedule
    var outerDiameter: Double {
        switch self {
        case .none: return 0
        case .half: return 0.840
        case .threeQuarter: return 1.050
        case .one: return 1.315
        case .oneAndQuarter: return 1.660
        case .oneAndHalf: return 1.900
        case .two: return 2.375
        case .twoAndHalf: return 2.875
        case .three: return 3.500
        case .four: return 4.500
        case .six: return 6.625
        case .eight: return 8.625
        case .ten: return 10.750
        case .twelve: return 12.750
        }
    }

    /// Wall thickness in inches for Schedule 40 (ASME B36.10M)
    var wallThicknessSch40: Double {
        switch self {
        case .none: return 0
        case .half: return 0.109
        case .threeQuarter: return 0.113
        case .one: return 0.133
        case .oneAndQuarter: return 0.140
        case .oneAndHalf: return 0.145
        case .two: return 0.154
        case .twoAndHalf: return 0.203
        case .three: return 0.216
        case .four: return 0.237
        case .six: return 0.280
        case .eight: return 0.322
        case .ten: return 0.365
        case .twelve: return 0.406
        }
    }

    /// Wall thickness in inches for Schedule 80 (ASME B36.10M)
    var wallThicknessSch80: Double {
        switch self {
        case .none: return 0
        case .half: return 0.147
        case .threeQuarter: return 0.154
        case .one: return 0.179
        case .oneAndQuarter: return 0.191
        case .oneAndHalf: return 0.200
        case .two: return 0.218
        case .twoAndHalf: return 0.276
        case .three: return 0.300
        case .four: return 0.337
        case .six: return 0.432
        case .eight: return 0.500
        case .ten: return 0.593
        case .twelve: return 0.687
        }
    }

    /// Inner diameter calculated from OD and wall thickness
    func innerDiameter(schedule: PipeSchedule = .sch40) -> Double {
        let wallThickness = schedule == .sch40 ? wallThicknessSch40 : wallThicknessSch80
        return outerDiameter - (2 * wallThickness)
    }

    /// Get wall thickness for a given schedule
    func wallThickness(schedule: PipeSchedule = .sch40) -> Double {
        switch schedule {
        case .sch40:
            return wallThicknessSch40
        case .sch80:
            return wallThicknessSch80
        case .sch160:
            return wallThicknessSch80 * 1.5 // Approximation
        case .custom(let thickness):
            return thickness
        }
    }
}

/// Pipe schedule enumeration
enum PipeSchedule: Codable, Equatable, Hashable {
    case sch40
    case sch80
    case sch160
    case custom(Double)

    var displayName: String {
        switch self {
        case .sch40: return "Schedule 40"
        case .sch80: return "Schedule 80"
        case .sch160: return "Schedule 160"
        case .custom(let thickness): return "Custom \(thickness)\""
        }
    }

    var abbreviation: String {
        switch self {
        case .sch40: return "SCH 40"
        case .sch80: return "SCH 80"
        case .sch160: return "SCH 160"
        case .custom(let thickness): return "WT \(thickness)\""
        }
    }
}
