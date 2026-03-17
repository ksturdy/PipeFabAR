//
//  FlangeDimensions.swift
//  PipeFabAR
//
//  Created by Claude on 2026-02-15.
//  ASME B16.5 - Pipe Flanges and Flanged Fittings
//

import Foundation

/// Detailed flange geometry for isometric rendering
struct FlangeDimensions {
    /// Flange outer diameter
    let outerDiameter: Double

    /// Bolt circle diameter
    let boltCircleDiameter: Double

    /// Number of bolt holes
    let boltHoleCount: Int

    /// Bolt hole diameter
    let boltHoleDiameter: Double

    /// Flange thickness
    let thickness: Double

    /// Raised face diameter (if applicable)
    let raisedFaceDiameter: Double

    /// Raised face height
    let raisedFaceHeight: Double

    /// Pressure rating
    let rating: FlangeRating
}

extension PipeSize {
    /// Get flange dimensions for a given pressure rating (ASME B16.5)
    func flangeDimensions(rating: FlangeRating = .class150) -> FlangeDimensions {
        switch rating {
        case .class150:
            return flange150Dimensions()
        case .class300:
            return flange300Dimensions()
        case .class600:
            return flange600Dimensions()
        }
    }

    /// Class 150 flange dimensions (ASME B16.5)
    private func flange150Dimensions() -> FlangeDimensions {
        switch self {
        case .none:
            return FlangeDimensions(outerDiameter: 0, boltCircleDiameter: 0, boltHoleCount: 0, boltHoleDiameter: 0, thickness: 0, raisedFaceDiameter: 0, raisedFaceHeight: 0, rating: .class150)

        case .half:
            return FlangeDimensions(
                outerDiameter: 3.75,
                boltCircleDiameter: 2.38,
                boltHoleCount: 4,
                boltHoleDiameter: 0.62,
                thickness: 0.44,
                raisedFaceDiameter: 1.38,
                raisedFaceHeight: 0.06,
                rating: .class150
            )

        case .threeQuarter:
            return FlangeDimensions(
                outerDiameter: 4.62,
                boltCircleDiameter: 3.12,
                boltHoleCount: 4,
                boltHoleDiameter: 0.62,
                thickness: 0.44,
                raisedFaceDiameter: 1.69,
                raisedFaceHeight: 0.06,
                rating: .class150
            )

        case .one:
            return FlangeDimensions(
                outerDiameter: 4.88,
                boltCircleDiameter: 3.50,
                boltHoleCount: 4,
                boltHoleDiameter: 0.62,
                thickness: 0.50,
                raisedFaceDiameter: 2.00,
                raisedFaceHeight: 0.06,
                rating: .class150
            )

        case .oneAndQuarter:
            return FlangeDimensions(
                outerDiameter: 5.25,
                boltCircleDiameter: 3.88,
                boltHoleCount: 4,
                boltHoleDiameter: 0.62,
                thickness: 0.56,
                raisedFaceDiameter: 2.50,
                raisedFaceHeight: 0.06,
                rating: .class150
            )

        case .oneAndHalf:
            return FlangeDimensions(
                outerDiameter: 6.12,
                boltCircleDiameter: 4.50,
                boltHoleCount: 4,
                boltHoleDiameter: 0.75,
                thickness: 0.56,
                raisedFaceDiameter: 2.88,
                raisedFaceHeight: 0.06,
                rating: .class150
            )

        case .two:
            return FlangeDimensions(
                outerDiameter: 6.50,
                boltCircleDiameter: 5.00,
                boltHoleCount: 4,
                boltHoleDiameter: 0.75,
                thickness: 0.62,
                raisedFaceDiameter: 3.62,
                raisedFaceHeight: 0.06,
                rating: .class150
            )

        case .twoAndHalf:
            return FlangeDimensions(
                outerDiameter: 7.50,
                boltCircleDiameter: 5.88,
                boltHoleCount: 4,
                boltHoleDiameter: 0.75,
                thickness: 0.69,
                raisedFaceDiameter: 4.12,
                raisedFaceHeight: 0.06,
                rating: .class150
            )

        case .three:
            return FlangeDimensions(
                outerDiameter: 8.25,
                boltCircleDiameter: 6.62,
                boltHoleCount: 4,
                boltHoleDiameter: 0.75,
                thickness: 0.75,
                raisedFaceDiameter: 5.00,
                raisedFaceHeight: 0.06,
                rating: .class150
            )

        case .four:
            return FlangeDimensions(
                outerDiameter: 10.00,
                boltCircleDiameter: 7.88,
                boltHoleCount: 8,
                boltHoleDiameter: 0.75,
                thickness: 0.94,
                raisedFaceDiameter: 6.19,
                raisedFaceHeight: 0.06,
                rating: .class150
            )

        case .six:
            return FlangeDimensions(
                outerDiameter: 12.50,
                boltCircleDiameter: 10.62,
                boltHoleCount: 8,
                boltHoleDiameter: 0.88,
                thickness: 1.00,
                raisedFaceDiameter: 8.50,
                raisedFaceHeight: 0.06,
                rating: .class150
            )

        case .eight:
            return FlangeDimensions(
                outerDiameter: 15.00,
                boltCircleDiameter: 13.00,
                boltHoleCount: 8,
                boltHoleDiameter: 0.88,
                thickness: 1.12,
                raisedFaceDiameter: 10.62,
                raisedFaceHeight: 0.06,
                rating: .class150
            )

        case .ten:
            return FlangeDimensions(
                outerDiameter: 17.50,
                boltCircleDiameter: 15.25,
                boltHoleCount: 12,
                boltHoleDiameter: 1.00,
                thickness: 1.19,
                raisedFaceDiameter: 13.00,
                raisedFaceHeight: 0.06,
                rating: .class150
            )

        case .twelve:
            return FlangeDimensions(
                outerDiameter: 20.50,
                boltCircleDiameter: 17.75,
                boltHoleCount: 12,
                boltHoleDiameter: 1.00,
                thickness: 1.25,
                raisedFaceDiameter: 15.25,
                raisedFaceHeight: 0.06,
                rating: .class150
            )
        }
    }

    /// Class 300 flange dimensions (ASME B16.5) - Abbreviated
    private func flange300Dimensions() -> FlangeDimensions {
        // Similar structure but with Class 300 dimensions
        // Thicker flanges, larger bolt holes, higher bolt counts
        let base = flange150Dimensions()
        return FlangeDimensions(
            outerDiameter: base.outerDiameter * 1.15,
            boltCircleDiameter: base.boltCircleDiameter * 1.1,
            boltHoleCount: base.boltHoleCount * 2,
            boltHoleDiameter: base.boltHoleDiameter * 1.2,
            thickness: base.thickness * 1.6,
            raisedFaceDiameter: base.raisedFaceDiameter,
            raisedFaceHeight: 0.25,
            rating: .class300
        )
    }

    /// Class 600 flange dimensions (ASME B16.5) - Abbreviated
    private func flange600Dimensions() -> FlangeDimensions {
        // Similar structure but with Class 600 dimensions
        let base = flange150Dimensions()
        return FlangeDimensions(
            outerDiameter: base.outerDiameter * 1.3,
            boltCircleDiameter: base.boltCircleDiameter * 1.2,
            boltHoleCount: base.boltHoleCount * 2,
            boltHoleDiameter: base.boltHoleDiameter * 1.4,
            thickness: base.thickness * 2.2,
            raisedFaceDiameter: base.raisedFaceDiameter,
            raisedFaceHeight: 0.25,
            rating: .class600
        )
    }
}
