//
//  ValveDimensions.swift
//  PipeFabAR
//
//  Created by Claude on 2026-02-15.
//  ASME B16.10 - Face-to-Face and End-to-End Dimensions of Valves
//

import Foundation

/// Valve types for dimensional lookup
enum ValveType: String, Codable, CaseIterable {
    case gate = "Gate Valve"
    case globe = "Globe Valve"
    case check = "Check Valve"
    case ball = "Ball Valve"
    case butterfly = "Butterfly Valve"
    case plug = "Plug Valve"

    var symbol: String {
        switch self {
        case .gate: return "⊗"
        case .globe: return "⊕"
        case .check: return "◐"
        case .ball: return "●"
        case .butterfly: return "◬"
        case .plug: return "◉"
        }
    }
}

/// Valve body dimensions for isometric rendering
struct ValveDimensions {
    /// Face-to-face dimension (flange to flange)
    let faceToFace: Double

    /// Body width (perpendicular to flow)
    let bodyWidth: Double

    /// Body height (for handwheel or actuator)
    let bodyHeight: Double

    /// Valve type
    let valveType: ValveType

    /// Pressure rating
    let rating: FlangeRating
}

extension PipeSize {
    /// Get valve dimensions for a given type and rating (ASME B16.10)
    func valveDimensions(valveType: ValveType, rating: FlangeRating = .class150) -> ValveDimensions {
        switch valveType {
        case .gate:
            return gateValveDimensions(rating: rating)
        case .globe:
            return globeValveDimensions(rating: rating)
        case .check:
            return checkValveDimensions(rating: rating)
        case .ball:
            return ballValveDimensions(rating: rating)
        case .butterfly:
            return butterflyValveDimensions(rating: rating)
        case .plug:
            return plugValveDimensions(rating: rating)
        }
    }

    /// Gate valve face-to-face dimensions (ASME B16.10)
    private func gateValveDimensions(rating: FlangeRating) -> ValveDimensions {
        let faceToFace: Double
        switch self {
        case .none: faceToFace = 0
        case .half: faceToFace = 3.5
        case .threeQuarter: faceToFace = 4.0
        case .one: faceToFace = 4.5
        case .oneAndQuarter: faceToFace = 5.0
        case .oneAndHalf: faceToFace = 5.5
        case .two: faceToFace = 6.5
        case .twoAndHalf: faceToFace = 7.5
        case .three: faceToFace = 8.0
        case .four: faceToFace = 9.0
        case .six: faceToFace = 10.5
        case .eight: faceToFace = 11.5
        case .ten: faceToFace = 13.0
        case .twelve: faceToFace = 14.0
        }

        return ValveDimensions(
            faceToFace: faceToFace,
            bodyWidth: outerDiameter * 2.5,
            bodyHeight: faceToFace * 1.5,
            valveType: .gate,
            rating: rating
        )
    }

    /// Globe valve face-to-face dimensions (ASME B16.10)
    private func globeValveDimensions(rating: FlangeRating) -> ValveDimensions {
        let faceToFace: Double
        switch self {
        case .none: faceToFace = 0
        case .half: faceToFace = 4.0
        case .threeQuarter: faceToFace = 4.5
        case .one: faceToFace = 5.0
        case .oneAndQuarter: faceToFace = 5.5
        case .oneAndHalf: faceToFace = 6.0
        case .two: faceToFace = 7.0
        case .twoAndHalf: faceToFace = 8.0
        case .three: faceToFace = 8.5
        case .four: faceToFace = 10.0
        case .six: faceToFace = 11.5
        case .eight: faceToFace = 13.0
        case .ten: faceToFace = 15.0
        case .twelve: faceToFace = 17.0
        }

        return ValveDimensions(
            faceToFace: faceToFace,
            bodyWidth: outerDiameter * 3.0,
            bodyHeight: faceToFace * 1.8,
            valveType: .globe,
            rating: rating
        )
    }

    /// Check valve face-to-face dimensions (ASME B16.10)
    private func checkValveDimensions(rating: FlangeRating) -> ValveDimensions {
        let faceToFace: Double
        switch self {
        case .none: faceToFace = 0
        case .half: faceToFace = 3.5
        case .threeQuarter: faceToFace = 4.0
        case .one: faceToFace = 4.5
        case .oneAndQuarter: faceToFace = 5.0
        case .oneAndHalf: faceToFace = 5.5
        case .two: faceToFace = 6.5
        case .twoAndHalf: faceToFace = 7.5
        case .three: faceToFace = 8.0
        case .four: faceToFace = 9.0
        case .six: faceToFace = 10.5
        case .eight: faceToFace = 11.5
        case .ten: faceToFace = 13.0
        case .twelve: faceToFace = 14.0
        }

        return ValveDimensions(
            faceToFace: faceToFace,
            bodyWidth: outerDiameter * 2.0,
            bodyHeight: outerDiameter * 2.5,
            valveType: .check,
            rating: rating
        )
    }

    /// Ball valve face-to-face dimensions (typically shorter than gate)
    private func ballValveDimensions(rating: FlangeRating) -> ValveDimensions {
        let faceToFace: Double
        switch self {
        case .none: faceToFace = 0
        case .half: faceToFace = 2.75
        case .threeQuarter: faceToFace = 3.0
        case .one: faceToFace = 3.5
        case .oneAndQuarter: faceToFace = 4.0
        case .oneAndHalf: faceToFace = 4.5
        case .two: faceToFace = 5.0
        case .twoAndHalf: faceToFace = 5.5
        case .three: faceToFace = 6.0
        case .four: faceToFace = 6.5
        case .six: faceToFace = 8.0
        case .eight: faceToFace = 9.0
        case .ten: faceToFace = 11.0
        case .twelve: faceToFace = 12.0
        }

        return ValveDimensions(
            faceToFace: faceToFace,
            bodyWidth: outerDiameter * 2.2,
            bodyHeight: faceToFace * 1.2,
            valveType: .ball,
            rating: rating
        )
    }

    /// Butterfly valve face-to-face dimensions (wafer style)
    private func butterflyValveDimensions(rating: FlangeRating) -> ValveDimensions {
        let faceToFace: Double
        switch self {
        case .none: faceToFace = 0
        case .half: faceToFace = 1.75
        case .threeQuarter: faceToFace = 1.75
        case .one: faceToFace = 1.75
        case .oneAndQuarter: faceToFace = 1.75
        case .oneAndHalf: faceToFace = 1.75
        case .two: faceToFace = 1.75
        case .twoAndHalf: faceToFace = 2.0
        case .three: faceToFace = 2.0
        case .four: faceToFace = 2.0
        case .six: faceToFace = 2.5
        case .eight: faceToFace = 3.0
        case .ten: faceToFace = 3.5
        case .twelve: faceToFace = 4.0
        }

        return ValveDimensions(
            faceToFace: faceToFace,
            bodyWidth: outerDiameter * 1.5,
            bodyHeight: outerDiameter * 3.0,
            valveType: .butterfly,
            rating: rating
        )
    }

    /// Plug valve face-to-face dimensions
    private func plugValveDimensions(rating: FlangeRating) -> ValveDimensions {
        let faceToFace: Double
        switch self {
        case .none: faceToFace = 0
        case .half: faceToFace = 3.5
        case .threeQuarter: faceToFace = 4.0
        case .one: faceToFace = 4.5
        case .oneAndQuarter: faceToFace = 5.0
        case .oneAndHalf: faceToFace = 5.5
        case .two: faceToFace = 6.0
        case .twoAndHalf: faceToFace = 7.0
        case .three: faceToFace = 7.5
        case .four: faceToFace = 8.5
        case .six: faceToFace = 10.0
        case .eight: faceToFace = 11.0
        case .ten: faceToFace = 12.5
        case .twelve: faceToFace = 14.0
        }

        return ValveDimensions(
            faceToFace: faceToFace,
            bodyWidth: outerDiameter * 2.5,
            bodyHeight: faceToFace * 1.3,
            valveType: .plug,
            rating: rating
        )
    }
}
