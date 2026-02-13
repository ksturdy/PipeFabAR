//
//  PipeSize.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import Foundation

/// Standard pipe sizes
enum PipeSize: String, Codable, CaseIterable {
    case none = "—"
    case half = "1/2\""
    case threeQuarter = "3/4\""
    case one = "1\""
    case oneAndQuarter = "1-1/4\""
    case oneAndHalf = "1-1/2\""
    case two = "2\""
    case twoAndHalf = "2-1/2\""
    case three = "3\""
    case four = "4\""
    case six = "6\""
    case eight = "8\""
    case ten = "10\""
    case twelve = "12\""

    /// Short display name with proper fractions
    var shortName: String {
        switch self {
        case .none: return "—"
        case .half: return "½\""
        case .threeQuarter: return "¾\""
        case .one: return "1\""
        case .oneAndQuarter: return "1¼\""
        case .oneAndHalf: return "1½\""
        case .two: return "2\""
        case .twoAndHalf: return "2½\""
        case .three: return "3\""
        case .four: return "4\""
        case .six: return "6\""
        case .eight: return "8\""
        case .ten: return "10\""
        case .twelve: return "12\""
        }
    }
}
