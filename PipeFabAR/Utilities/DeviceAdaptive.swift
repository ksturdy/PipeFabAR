//
//  DeviceAdaptive.swift
//  PipeFabAR
//
//  Created for iPad UI optimization
//

import SwiftUI

// MARK: - View Modifiers for Conditional Layouts

extension View {
    /// Conditionally render different layouts based on horizontal size class
    /// - Parameters:
    ///   - iPad: View builder for iPad (regular width) layout
    ///   - iPhone: View builder for iPhone (compact width) layout
    func adaptiveLayout<iPadContent: View, iPhoneContent: View>(
        iPad: @escaping () -> iPadContent,
        iPhone: @escaping () -> iPhoneContent
    ) -> some View {
        modifier(AdaptiveLayoutModifier(iPad: iPad, iPhone: iPhone))
    }

    /// Apply content only on iPad (regular horizontal size class)
    /// - Parameter content: View builder for iPad-only content
    func iPadOnly<Content: View>(
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        modifier(iPadOnlyModifier(content: content))
    }

    /// Apply content only on iPhone (compact horizontal size class)
    /// - Parameter content: View builder for iPhone-only content
    func iPhoneOnly<Content: View>(
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        modifier(iPhoneOnlyModifier(content: content))
    }
}

// MARK: - Adaptive Layout Modifier

struct AdaptiveLayoutModifier<iPadContent: View, iPhoneContent: View>: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let iPad: () -> iPadContent
    let iPhone: () -> iPhoneContent

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            iPad()
        } else {
            iPhone()
        }
    }
}

// MARK: - iPad Only Modifier

struct iPadOnlyModifier<Content: View>: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let content: () -> Content

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            self.content()
        } else {
            content
        }
    }
}

// MARK: - iPhone Only Modifier

struct iPhoneOnlyModifier<Content: View>: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let content: () -> Content

    func body(content: Content) -> some View {
        if horizontalSizeClass == .compact {
            self.content()
        } else {
            content
        }
    }
}

// MARK: - Device Detection Helpers

extension EnvironmentValues {
    /// Check if current device is iPad (regular horizontal size class)
    var isiPad: Bool {
        horizontalSizeClass == .regular
    }

    /// Check if current device is iPhone (compact horizontal size class)
    var isiPhone: Bool {
        horizontalSizeClass == .compact
    }
}
