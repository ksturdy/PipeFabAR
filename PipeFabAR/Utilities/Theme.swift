//
//  Theme.swift
//  PipeFabAR
//
//  Created on 2026-01-31.
//

import SwiftUI

/// PipeFabAR Brand Theme and Design System
struct PipeFabARTheme {

    // MARK: - Brand Colors

    /// Primary brand color - vibrant blue matching the logo
    static let primaryBlue = Color(hex: "#0A7AFF") ?? Color.blue

    /// Secondary brand color - darker blue for contrast
    static let secondaryBlue = Color(hex: "#005BBB") ?? Color.blue

    /// Accent color - lighter blue for highlights
    static let accentBlue = Color(hex: "#5AC8FA") ?? Color.cyan

    /// Dark background overlay
    static let darkOverlay = Color.black.opacity(0.75)

    /// Light background overlay
    static let lightOverlay = Color.white.opacity(0.9)

    // MARK: - Typography

    /// Large brand title font
    static let brandTitleFont = Font.system(size: 32, weight: .bold, design: .rounded)

    /// Medium brand title font
    static let brandSubtitleFont = Font.system(size: 20, weight: .semibold, design: .rounded)

    /// Small brand label font
    static let brandLabelFont = Font.system(size: 14, weight: .medium, design: .rounded)

    /// Tiny brand caption font
    static let brandCaptionFont = Font.system(size: 10, weight: .regular, design: .rounded)

    // MARK: - Spacing

    /// Standard padding for branded elements
    static let standardPadding: CGFloat = 16

    /// Compact padding for small elements
    static let compactPadding: CGFloat = 8

    /// Large padding for headers
    static let largePadding: CGFloat = 24

    // MARK: - Corner Radius

    /// Standard corner radius
    static let standardCornerRadius: CGFloat = 12

    /// Small corner radius
    static let smallCornerRadius: CGFloat = 8

    /// Large corner radius
    static let largeCornerRadius: CGFloat = 16

    // MARK: - Shadows

    /// Standard shadow for cards and elevated elements
    static func standardShadow() -> some View {
        EmptyView()
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    /// Light shadow for subtle elevation
    static func lightShadow() -> some View {
        EmptyView()
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Gradients

    /// Primary brand gradient
    static let brandGradient = LinearGradient(
        colors: [primaryBlue, secondaryBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle background gradient
    static let backgroundGradient = LinearGradient(
        colors: [Color(.systemBackground), Color(.systemGray6)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - iPad Layout Constants

    /// Sidebar width for iPad split views (drawing tool sidebar, navigation sidebar)
    static let sidebarWidth: CGFloat = 280

    /// Wide sidebar width for iPad info panels
    static let wideSidebarWidth: CGFloat = 360

    /// Maximum form width on iPad (centered forms)
    static let maxFormWidth: CGFloat = 600

    /// Adaptive padding (16pt iPhone, 24pt iPad)
    /// - Parameter sizeClass: The horizontal size class
    /// - Returns: Appropriate padding for device
    static func adaptivePadding(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? largePadding : standardPadding
    }

    /// Adaptive grid minimum size (scales base size by 1.5x on iPad)
    /// - Parameters:
    ///   - base: Base minimum size for iPhone
    ///   - sizeClass: The horizontal size class
    /// - Returns: Appropriate grid item minimum for device
    static func adaptiveGridMinimum(base: CGFloat, for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? base * 1.5 : base
    }

    /// Adaptive spacing multiplier (1.5x on iPad)
    /// - Parameter sizeClass: The horizontal size class
    /// - Returns: Spacing multiplier for device
    static func adaptiveSpacingMultiplier(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 1.5 : 1.0
    }
}

// MARK: - Brand Text Modifier

/// Modifier to apply PipeFabAR brand styling to text
struct BrandTextModifier: ViewModifier {
    let style: BrandTextStyle

    enum BrandTextStyle {
        case title
        case subtitle
        case label
        case caption
    }

    func body(content: Content) -> some View {
        switch style {
        case .title:
            content
                .font(PipeFabARTheme.brandTitleFont)
                .foregroundColor(PipeFabARTheme.primaryBlue)
        case .subtitle:
            content
                .font(PipeFabARTheme.brandSubtitleFont)
                .foregroundColor(PipeFabARTheme.secondaryBlue)
        case .label:
            content
                .font(PipeFabARTheme.brandLabelFont)
                .foregroundColor(PipeFabARTheme.primaryBlue)
        case .caption:
            content
                .font(PipeFabARTheme.brandCaptionFont)
                .foregroundColor(.secondary)
        }
    }
}

extension View {
    /// Apply PipeFabAR brand text styling
    func brandText(_ style: BrandTextModifier.BrandTextStyle) -> some View {
        modifier(BrandTextModifier(style: style))
    }
}
