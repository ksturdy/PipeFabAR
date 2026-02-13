//
//  SpoolCard.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI

/// Card displaying a spool
struct SpoolCard: View {
    let spool: Spool

    var statusColor: Color {
        switch spool.status {
        case "Draft": return .gray
        case "Ready for Fabrication": return .green
        case "Fabricated": return .blue
        case "Installed": return .purple
        default: return .gray
        }
    }

    var systemColor: Color? {
        guard let systemTypeRaw = spool.systemType,
              let systemType = SystemType(rawValue: systemTypeRaw) else {
            return nil
        }
        return systemType.swiftUIColor
    }

    var body: some View {
        VStack(spacing: 8) {
            // Thumbnail or placeholder
            ZStack {
                if let thumbnailData = spool.thumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 100)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 100)
                        .overlay(
                            Image(systemName: "cylinder.fill")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        )
                }

                // System type indicator
                if let systemColor = systemColor {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(systemColor)
                                .frame(width: 12, height: 12)
                                .padding(6)
                        }
                        Spacer()
                    }
                }

                // Logo - Bottom Left
                VStack {
                    Spacer()
                    HStack {
                        BrandingView(size: 24)
                        Spacer()
                    }
                }
                .padding(6)
            }
            .cornerRadius(8)

            // Spool info
            VStack(alignment: .leading, spacing: 4) {
                Text(spool.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)

                    Text(spool.status)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    SpoolCard(
        spool: Spool(
            name: "2026-001-001",
            systemType: SystemType.hotWater.rawValue,
            status: "Ready for Fabrication"
        )
    )
    .frame(width: 150)
    .padding()
    .background(Color(.systemGroupedBackground))
}
