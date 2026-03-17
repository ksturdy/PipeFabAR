//
//  FittingDimensions.swift
//  PipeFabAR
//
//  Created by Claude on 2026-02-15.
//  ASME B16.9 - Factory-Made Wrought Buttwelding Fittings
//

import Foundation

/// Fitting dimensions per ASME B16.9
extension FittingType {
    /// Center-to-face dimension in inches (ASME B16.9)
    /// This is the distance from the center of the fitting to the welding face
    func centerToFace(pipeSize: PipeSize) -> Double {
        switch self {
        case .none, .coupling, .cap:
            return 0

        case .elbow90:
            // Long radius 90° elbow: C = 1.5 × NPS
            return elbowCenterToFace(pipeSize: pipeSize, isLongRadius: true)

        case .elbow45:
            // 45° elbow: C = 1.0 × NPS (typically)
            return elbowCenterToFace(pipeSize: pipeSize, isLongRadius: false)

        case .tee:
            // Tee run dimension (same as long radius elbow)
            return teeCenterToEnd(pipeSize: pipeSize)

        case .reducer:
            // Concentric/eccentric reducer length
            return reducerLength(pipeSize: pipeSize)

        case .flange:
            // Flange thickness
            return flangeThickness(pipeSize: pipeSize, rating: .class150)

        case .valve:
            // Face-to-face dimension (varies by valve type)
            // Using gate valve as default
            return gateValveFaceToFace(pipeSize: pipeSize)
        }
    }

    /// 90° or 45° elbow center-to-face dimensions (ASME B16.9)
    private func elbowCenterToFace(pipeSize: PipeSize, isLongRadius: Bool) -> Double {
        if isLongRadius {
            // Long radius: C = 1.5 × NPS
            // But actual dimensions from ASME B16.9 Table 2
            switch pipeSize {
            case .none: return 0
            case .half: return 1.5
            case .threeQuarter: return 1.125
            case .one: return 1.5
            case .oneAndQuarter: return 1.875
            case .oneAndHalf: return 2.25
            case .two: return 3.0
            case .twoAndHalf: return 3.75
            case .three: return 4.5
            case .four: return 6.0
            case .six: return 9.0
            case .eight: return 12.0
            case .ten: return 15.0
            case .twelve: return 18.0
            }
        } else {
            // 45° elbow or short radius
            return pipeSize.nominalDiameter * 1.0
        }
    }

    /// Tee center-to-end dimension (ASME B16.9)
    private func teeCenterToEnd(pipeSize: PipeSize) -> Double {
        // Same as long radius elbow center-to-face
        switch pipeSize {
        case .none: return 0
        case .half: return 1.5
        case .threeQuarter: return 1.125
        case .one: return 1.5
        case .oneAndQuarter: return 1.875
        case .oneAndHalf: return 2.25
        case .two: return 3.0
        case .twoAndHalf: return 3.75
        case .three: return 4.5
        case .four: return 6.0
        case .six: return 9.0
        case .eight: return 12.0
        case .ten: return 15.0
        case .twelve: return 18.0
        }
    }

    /// Reducer length (ASME B16.9)
    private func reducerLength(pipeSize: PipeSize) -> Double {
        // Concentric/eccentric reducer face-to-face
        // Approximate: 2 × larger pipe OD
        return pipeSize.outerDiameter * 2.0
    }

    /// Flange thickness by pressure rating
    private func flangeThickness(pipeSize: PipeSize, rating: FlangeRating) -> Double {
        switch rating {
        case .class150:
            return flange150Thickness(pipeSize: pipeSize)
        case .class300:
            return flange300Thickness(pipeSize: pipeSize)
        case .class600:
            return flange600Thickness(pipeSize: pipeSize)
        }
    }

    /// Gate valve face-to-face dimension (ASME B16.10)
    private func gateValveFaceToFace(pipeSize: PipeSize) -> Double {
        // Class 150 gate valve face-to-face (ASME B16.10)
        switch pipeSize {
        case .none: return 0
        case .half: return 3.5
        case .threeQuarter: return 4.0
        case .one: return 4.5
        case .oneAndQuarter: return 5.0
        case .oneAndHalf: return 5.5
        case .two: return 6.5
        case .twoAndHalf: return 7.5
        case .three: return 8.0
        case .four: return 9.0
        case .six: return 10.5
        case .eight: return 11.5
        case .ten: return 13.0
        case .twelve: return 14.0
        }
    }

    /// Elbow radius for rendering curved elbows
    func elbowRadius(pipeSize: PipeSize) -> Double {
        // Long radius = 1.5 × NPS
        // Short radius = 1.0 × NPS
        return 1.5 * pipeSize.nominalDiameter
    }
}

/// Flange pressure rating classes
enum FlangeRating: String, Codable, CaseIterable {
    case class150 = "150#"
    case class300 = "300#"
    case class600 = "600#"

    var displayName: String { rawValue }
}

/// Class 150 flange thickness (ASME B16.5)
private func flange150Thickness(pipeSize: PipeSize) -> Double {
    switch pipeSize {
    case .none: return 0
    case .half: return 0.44
    case .threeQuarter: return 0.44
    case .one: return 0.50
    case .oneAndQuarter: return 0.56
    case .oneAndHalf: return 0.56
    case .two: return 0.62
    case .twoAndHalf: return 0.69
    case .three: return 0.75
    case .four: return 0.94
    case .six: return 1.00
    case .eight: return 1.12
    case .ten: return 1.19
    case .twelve: return 1.25
    }
}

/// Class 300 flange thickness (ASME B16.5)
private func flange300Thickness(pipeSize: PipeSize) -> Double {
    switch pipeSize {
    case .none: return 0
    case .half: return 0.56
    case .threeQuarter: return 0.56
    case .one: return 0.62
    case .oneAndQuarter: return 0.69
    case .oneAndHalf: return 0.69
    case .two: return 0.75
    case .twoAndHalf: return 0.88
    case .three: return 1.00
    case .four: return 1.19
    case .six: return 1.44
    case .eight: return 1.62
    case .ten: return 1.88
    case .twelve: return 2.00
    }
}

/// Class 600 flange thickness (ASME B16.5)
private func flange600Thickness(pipeSize: PipeSize) -> Double {
    switch pipeSize {
    case .none: return 0
    case .half: return 0.69
    case .threeQuarter: return 0.69
    case .one: return 0.81
    case .oneAndQuarter: return 0.88
    case .oneAndHalf: return 0.88
    case .two: return 1.00
    case .twoAndHalf: return 1.19
    case .three: return 1.38
    case .four: return 1.62
    case .six: return 2.00
    case .eight: return 2.25
    case .ten: return 2.50
    case .twelve: return 2.75
    }
}
