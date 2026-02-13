//
//  ThumbnailGenerator.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI
import UIKit

/// Generates thumbnail images for spool drawings
class ThumbnailGenerator {
    /// Generate a thumbnail from pipe points
    /// - Parameters:
    ///   - pipePoints: Array of pipe points to render
    ///   - size: Size of the thumbnail (default: 300x300)
    /// - Returns: Thumbnail image data, or nil if generation fails
    static func generate(from pipePoints: [PipePoint], size: CGSize = CGSize(width: 300, height: 300)) async -> Data? {
        guard !pipePoints.isEmpty else { return nil }

        return await MainActor.run {
            // Create a simplified drawing view
            let view = ThumbnailDrawingView(pipePoints: pipePoints)
                .frame(width: size.width, height: size.height)
                .background(Color.white)

            let renderer = ImageRenderer(content: view)
            renderer.scale = 2.0 // Retina resolution

            guard let uiImage = renderer.uiImage else {
                return nil
            }

            return uiImage.pngData()
        }
    }
}

/// Simplified view for rendering thumbnails
private struct ThumbnailDrawingView: View {
    let pipePoints: [PipePoint]

    var body: some View {
        Canvas { context, size in
            // Calculate bounds to fit all points
            guard pipePoints.count >= 2 else { return }

            let positions = pipePoints.map { $0.position }
            let minX = positions.map { $0.x }.min() ?? 0
            let maxX = positions.map { $0.x }.max() ?? 0
            let minY = positions.map { $0.y }.min() ?? 0
            let maxY = positions.map { $0.y }.max() ?? 0

            let width = maxX - minX
            let height = maxY - minY
            let scale = min(size.width / width, size.height / height) * 0.8 // 80% to add padding

            let offsetX = (size.width - width * scale) / 2 - minX * scale
            let offsetY = (size.height - height * scale) / 2 - minY * scale

            // Draw pipes
            for i in 0..<(pipePoints.count - 1) {
                let start = pipePoints[i].position
                let end = pipePoints[i + 1].position

                var path = Path()
                path.move(to: CGPoint(x: start.x * scale + offsetX, y: start.y * scale + offsetY))
                path.addLine(to: CGPoint(x: end.x * scale + offsetX, y: end.y * scale + offsetY))

                context.stroke(path, with: .color(.green), lineWidth: 3)
            }

            // Draw points
            for (index, point) in pipePoints.enumerated() {
                let isFirst = index == 0
                let isLast = index == pipePoints.count - 1
                let color: Color = isFirst ? .green : (isLast ? .red : .blue)

                let center = CGPoint(
                    x: point.position.x * scale + offsetX,
                    y: point.position.y * scale + offsetY
                )

                var circlePath = Path()
                circlePath.addEllipse(in: CGRect(
                    x: center.x - 6,
                    y: center.y - 6,
                    width: 12,
                    height: 12
                ))

                context.fill(circlePath, with: .color(color))
            }
        }
    }
}
