//
//  WeldbendCatalog.swift
//  PipeFabAR
//
//  Weldbend manufacturer catalog data for carbon steel butt-weld fittings.
//  Part numbers, weights, and material specifications.
//  Weldbend is the only domestic US manufacturer of both CS fittings and flanges.
//

import Foundation

// MARK: - Manufacturer Catalog Entry

struct ManufacturerCatalogEntry {
    let manufacturer: String
    let partNumber: String
    let description: String
    let fittingType: FittingType
    let pipeSize: PipeSize
    let schedule: String
    let material: String
    let standard: String
    let weightLbs: Double
    let imageName: String?
}

// MARK: - Weldbend Catalog

enum WeldbendCatalog {

    static let manufacturer = "Weldbend"
    static let materialGrade = "ASTM A234 WPB"
    static let fittingStandard = "ASME B16.9"
    static let flangeStandard = "ASME B16.5"
    static let defaultSchedule = "SCH 40/STD"

    // MARK: - Catalog Entry Lookup

    /// Returns the full catalog entry for a fitting type and pipe size
    static func entry(for fittingType: FittingType, pipeSize: PipeSize) -> ManufacturerCatalogEntry? {
        guard pipeSize != .none else { return nil }

        switch fittingType {
        case .elbow90:
            return ManufacturerCatalogEntry(
                manufacturer: manufacturer,
                partNumber: partNumber(fittingType: fittingType, pipeSize: pipeSize),
                description: "90° LR Elbow, \(pipeSize.shortName), \(defaultSchedule)",
                fittingType: fittingType,
                pipeSize: pipeSize,
                schedule: defaultSchedule,
                material: materialGrade,
                standard: fittingStandard,
                weightLbs: weight(fittingType: fittingType, pipeSize: pipeSize),
                imageName: "FittingImages/weldbend_elbow90"
            )
        case .elbow45:
            return ManufacturerCatalogEntry(
                manufacturer: manufacturer,
                partNumber: partNumber(fittingType: fittingType, pipeSize: pipeSize),
                description: "45° LR Elbow, \(pipeSize.shortName), \(defaultSchedule)",
                fittingType: fittingType,
                pipeSize: pipeSize,
                schedule: defaultSchedule,
                material: materialGrade,
                standard: fittingStandard,
                weightLbs: weight(fittingType: fittingType, pipeSize: pipeSize),
                imageName: "FittingImages/weldbend_elbow45"
            )
        case .tee:
            return ManufacturerCatalogEntry(
                manufacturer: manufacturer,
                partNumber: partNumber(fittingType: fittingType, pipeSize: pipeSize),
                description: "Straight Tee, \(pipeSize.shortName), \(defaultSchedule)",
                fittingType: fittingType,
                pipeSize: pipeSize,
                schedule: defaultSchedule,
                material: materialGrade,
                standard: fittingStandard,
                weightLbs: weight(fittingType: fittingType, pipeSize: pipeSize),
                imageName: "FittingImages/weldbend_tee"
            )
        case .reducer:
            return ManufacturerCatalogEntry(
                manufacturer: manufacturer,
                partNumber: partNumber(fittingType: fittingType, pipeSize: pipeSize),
                description: "Concentric Reducer, \(pipeSize.shortName), \(defaultSchedule)",
                fittingType: fittingType,
                pipeSize: pipeSize,
                schedule: defaultSchedule,
                material: materialGrade,
                standard: fittingStandard,
                weightLbs: weight(fittingType: fittingType, pipeSize: pipeSize),
                imageName: "FittingImages/weldbend_reducer"
            )
        case .cap:
            return ManufacturerCatalogEntry(
                manufacturer: manufacturer,
                partNumber: partNumber(fittingType: fittingType, pipeSize: pipeSize),
                description: "Cap, \(pipeSize.shortName), \(defaultSchedule)",
                fittingType: fittingType,
                pipeSize: pipeSize,
                schedule: defaultSchedule,
                material: materialGrade,
                standard: fittingStandard,
                weightLbs: weight(fittingType: fittingType, pipeSize: pipeSize),
                imageName: "FittingImages/weldbend_cap"
            )
        case .flange:
            return ManufacturerCatalogEntry(
                manufacturer: manufacturer,
                partNumber: flangePartNumber(pipeSize: pipeSize),
                description: "Weld Neck Flange, \(pipeSize.shortName), 150#",
                fittingType: fittingType,
                pipeSize: pipeSize,
                schedule: "150#",
                material: "ASTM A105",
                standard: flangeStandard,
                weightLbs: flangeWeight(pipeSize: pipeSize),
                imageName: "FittingImages/weldbend_flange_wn"
            )
        case .coupling:
            return ManufacturerCatalogEntry(
                manufacturer: manufacturer,
                partNumber: partNumber(fittingType: fittingType, pipeSize: pipeSize),
                description: "Coupling, \(pipeSize.shortName), \(defaultSchedule)",
                fittingType: fittingType,
                pipeSize: pipeSize,
                schedule: defaultSchedule,
                material: materialGrade,
                standard: fittingStandard,
                weightLbs: weight(fittingType: fittingType, pipeSize: pipeSize),
                imageName: nil
            )
        case .valve, .none:
            return nil
        }
    }

    // MARK: - Part Number Generation

    /// Weldbend part number format: XXX-YYY-ZZZ
    /// XXX = Fitting type prefix
    /// YYY = Primary pipe size code
    /// ZZZ = Secondary size code (000 for non-reducing)
    static func partNumber(fittingType: FittingType, pipeSize: PipeSize, secondarySize: PipeSize? = nil) -> String {
        let prefix = fittingTypePrefix(fittingType)
        let primaryCode = pipeSizeCode(pipeSize)
        let secondaryCode = secondarySize.map { pipeSizeCode($0) } ?? "000"
        return "\(prefix)-\(primaryCode)-\(secondaryCode)"
    }

    /// Fitting type prefix codes
    private static func fittingTypePrefix(_ type: FittingType) -> String {
        switch type {
        case .elbow90:  return "010"  // 90° LR Elbow, SCH 40/STD
        case .elbow45:  return "020"  // 45° LR Elbow
        case .tee:      return "050"  // Straight Tee
        case .reducer:  return "090"  // Concentric Reducer
        case .cap:      return "080"  // Cap
        case .coupling: return "070"  // Coupling
        case .flange:   return "100"  // Weld Neck Flange (approx)
        case .valve:    return "000"
        case .none:     return "000"
        }
    }

    /// Pipe size encoding: first 2 digits = whole inches, 3rd digit = quarter inches
    /// Example: 1-1/4" = 011 (1 inch + 1 quarter)
    private static func pipeSizeCode(_ size: PipeSize) -> String {
        switch size {
        case .none:           return "000"
        case .half:           return "002"  // 0" + 2/4" = ½"
        case .threeQuarter:   return "003"  // 0" + 3/4" = ¾"
        case .one:            return "010"  // 1" + 0/4"
        case .oneAndQuarter:  return "011"  // 1" + 1/4" = 1¼"
        case .oneAndHalf:     return "012"  // 1" + 2/4" = 1½"
        case .two:            return "020"  // 2" + 0/4"
        case .twoAndHalf:     return "022"  // 2" + 2/4" = 2½"
        case .three:          return "030"  // 3" + 0/4"
        case .four:           return "040"  // 4" + 0/4"
        case .six:            return "060"  // 6" + 0/4"
        case .eight:          return "080"  // 8" + 0/4"
        case .ten:            return "100"  // 10" + 0/4"
        case .twelve:         return "120"  // 12" + 0/4"
        }
    }

    /// Flange part numbers (Weldbend WN flanges, 150#)
    private static func flangePartNumber(pipeSize: PipeSize) -> String {
        // Weldbend flange part numbers use a different prefix scheme
        let sizeCode = pipeSizeCode(pipeSize)
        return "100-\(sizeCode)-000"
    }

    // MARK: - Weights (Approximate, SCH 40/STD, lbs)

    /// Approximate fitting weight in pounds (SCH 40/STD)
    static func weight(fittingType: FittingType, pipeSize: PipeSize) -> Double {
        switch fittingType {
        case .elbow90:  return elbow90Weight(pipeSize)
        case .elbow45:  return elbow45Weight(pipeSize)
        case .tee:      return teeWeight(pipeSize)
        case .reducer:  return reducerWeight(pipeSize)
        case .cap:      return capWeight(pipeSize)
        case .flange:   return flangeWeight(pipeSize: pipeSize)
        case .coupling: return couplingWeight(pipeSize)
        case .valve:    return 0
        case .none:     return 0
        }
    }

    /// 90° Long Radius Elbow weights (SCH 40, lbs)
    private static func elbow90Weight(_ size: PipeSize) -> Double {
        switch size {
        case .none:           return 0
        case .half:           return 0.3
        case .threeQuarter:   return 0.4
        case .one:            return 0.7
        case .oneAndQuarter:  return 1.1
        case .oneAndHalf:     return 1.5
        case .two:            return 2.1
        case .twoAndHalf:     return 4.0
        case .three:          return 5.5
        case .four:           return 10.0
        case .six:            return 25.0
        case .eight:          return 50.0
        case .ten:            return 85.0
        case .twelve:         return 123.0
        }
    }

    /// 45° Elbow weights (SCH 40, lbs) — approximately 60% of 90°
    private static func elbow45Weight(_ size: PipeSize) -> Double {
        switch size {
        case .none:           return 0
        case .half:           return 0.2
        case .threeQuarter:   return 0.3
        case .one:            return 0.4
        case .oneAndQuarter:  return 0.7
        case .oneAndHalf:     return 0.9
        case .two:            return 1.3
        case .twoAndHalf:     return 2.4
        case .three:          return 3.3
        case .four:           return 6.0
        case .six:            return 15.0
        case .eight:          return 30.0
        case .ten:            return 51.0
        case .twelve:         return 74.0
        }
    }

    /// Straight Tee weights (SCH 40, lbs)
    private static func teeWeight(_ size: PipeSize) -> Double {
        switch size {
        case .none:           return 0
        case .half:           return 0.5
        case .threeQuarter:   return 0.7
        case .one:            return 1.1
        case .oneAndQuarter:  return 1.7
        case .oneAndHalf:     return 2.3
        case .two:            return 3.6
        case .twoAndHalf:     return 6.5
        case .three:          return 9.5
        case .four:           return 17.0
        case .six:            return 44.0
        case .eight:          return 82.0
        case .ten:            return 140.0
        case .twelve:         return 205.0
        }
    }

    /// Concentric Reducer weights (SCH 40, lbs) — one standard size reduction
    private static func reducerWeight(_ size: PipeSize) -> Double {
        switch size {
        case .none:           return 0
        case .half:           return 0.2
        case .threeQuarter:   return 0.3
        case .one:            return 0.4
        case .oneAndQuarter:  return 0.6
        case .oneAndHalf:     return 0.8
        case .two:            return 1.2
        case .twoAndHalf:     return 2.0
        case .three:          return 3.0
        case .four:           return 5.0
        case .six:            return 12.0
        case .eight:          return 23.0
        case .ten:            return 40.0
        case .twelve:         return 58.0
        }
    }

    /// Cap weights (SCH 40, lbs)
    private static func capWeight(_ size: PipeSize) -> Double {
        switch size {
        case .none:           return 0
        case .half:           return 0.2
        case .threeQuarter:   return 0.2
        case .one:            return 0.3
        case .oneAndQuarter:  return 0.4
        case .oneAndHalf:     return 0.5
        case .two:            return 0.8
        case .twoAndHalf:     return 1.3
        case .three:          return 2.0
        case .four:           return 3.5
        case .six:            return 7.5
        case .eight:          return 14.0
        case .ten:            return 23.0
        case .twelve:         return 34.0
        }
    }

    /// Coupling weights (SCH 40, lbs) — approximate
    private static func couplingWeight(_ size: PipeSize) -> Double {
        switch size {
        case .none:           return 0
        case .half:           return 0.1
        case .threeQuarter:   return 0.2
        case .one:            return 0.3
        case .oneAndQuarter:  return 0.4
        case .oneAndHalf:     return 0.5
        case .two:            return 0.8
        case .twoAndHalf:     return 1.2
        case .three:          return 1.7
        case .four:           return 2.8
        case .six:            return 6.0
        case .eight:          return 11.0
        case .ten:            return 18.0
        case .twelve:         return 26.0
        }
    }

    /// Weld Neck Flange weights (150#, lbs)
    private static func flangeWeight(pipeSize: PipeSize) -> Double {
        switch pipeSize {
        case .none:           return 0
        case .half:           return 2.0
        case .threeQuarter:   return 2.0
        case .one:            return 3.0
        case .oneAndQuarter:  return 4.0
        case .oneAndHalf:     return 4.0
        case .two:            return 6.0
        case .twoAndHalf:     return 8.0
        case .three:          return 10.0
        case .four:           return 15.0
        case .six:            return 24.0
        case .eight:          return 38.0
        case .ten:            return 55.0
        case .twelve:         return 70.0
        }
    }

    // MARK: - Display Helpers

    /// Formatted weight string
    static func weightString(fittingType: FittingType, pipeSize: PipeSize) -> String {
        let w = weight(fittingType: fittingType, pipeSize: pipeSize)
        if w <= 0 { return "—" }
        if w < 1.0 {
            return String(format: "%.1f lbs", w)
        } else {
            return String(format: "%.0f lbs", w)
        }
    }
}
