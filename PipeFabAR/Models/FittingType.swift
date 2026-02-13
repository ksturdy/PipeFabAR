//
//  FittingType.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import Foundation

/// Types of pipe fittings available
enum FittingType: String, Codable, CaseIterable {
    case none = "None"
    case elbow90 = "90° Elbow"
    case elbow45 = "45° Elbow"
    case tee = "Tee"
    case coupling = "Coupling"
    case reducer = "Reducer"
    case cap = "Cap"
    case valve = "Valve"
    case flange = "Flange"

    /// Visual symbol representation for the fitting
    var symbol: String {
        switch self {
        case .none: return ""
        case .elbow90: return "⌐"
        case .elbow45: return "∠"
        case .tee: return "⊥"
        case .coupling: return "="
        case .reducer: return "◇"
        case .cap: return "■"
        case .valve: return "⊗"
        case .flange: return "◎"
        }
    }
}
