//
//  BrandingView.swift
//  PipeFabAR
//
//  Created on 2026-01-31.
//

import SwiftUI

/// Simple logo component for branding
struct BrandingView: View {
    let size: CGFloat

    init(size: CGFloat = 32) {
        self.size = size
    }

    var body: some View {
        Image("AppLogo")
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.2)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
            )
            .cornerRadius(size * 0.2)
    }
}

#Preview {
    VStack(spacing: 20) {
        BrandingView(size: 24)
        BrandingView(size: 32)
        BrandingView(size: 48)
    }
    .padding()
}
