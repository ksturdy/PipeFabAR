//
//  IsometricRenderer.swift
//  PipeFabAR
//
//  Created by Claude on 2026-02-15.
//  Isometric projection utilities for accurate pipe and fitting rendering
//

import SwiftUI
import CoreGraphics

/// Isometric projection utilities for 2D rendering of 3D pipe components
struct IsometricRenderer {
    /// Scale factor for converting inches to points (2.0 = 2 points per inch)
    let scale: CGFloat

    init(scale: CGFloat = 2.0) {
        self.scale = scale
    }

    // MARK: - Isometric Projection Math

    /// Convert 3D coordinates to isometric 2D projection
    /// Standard isometric angles: 30° left, 30° right, vertical up
    func project3DPoint(x: Double, y: Double, z: Double) -> CGPoint {
        // Isometric projection formulas
        let screenX = (x - y) * cos(30.0 * .pi / 180.0)
        let screenY = (x + y) * sin(30.0 * .pi / 180.0) - z
        return CGPoint(x: screenX * scale, y: screenY * scale)
    }

    /// Get the isometric angle for a given direction
    /// - Parameter angle: Angle in degrees (0° = right, 90° = up, etc.)
    /// - Returns: Isometric projected angle
    func isometricAngle(from angle: CGFloat) -> CGFloat {
        // Map standard angles to isometric angles
        switch angle {
        case 0, 360: return 330  // Right → 30° down-right
        case 30: return 0        // NW → Horizontal right
        case 90: return 90       // Up → Vertical up
        case 150: return 180     // NE → Horizontal left
        case 210: return 180     // SE → Horizontal left (back)
        case 270: return 270     // Down → Vertical down
        case 330: return 0       // SW → Horizontal right (back)
        default: return angle
        }
    }

    // MARK: - Ellipse Drawing (for pipe ends and circular features)

    /// Draw an isometric ellipse (circle in 3D viewed in isometric)
    /// Used for pipe ends, flanges, etc.
    func ellipse(at center: CGPoint, diameter: Double, angle: CGFloat) -> Path {
        var path = Path()

        // Ellipse parameters for isometric projection
        let radiusMajor = CGFloat(diameter / 2.0) * scale
        let radiusMinor = radiusMajor * sin(30.0 * .pi / 180.0) // ≈ 0.5

        // Determine orientation based on pipe direction
        let rotation: CGFloat
        if abs(angle - 90) < 15 || abs(angle - 270) < 15 {
            // Vertical pipe: ellipse is horizontal
            rotation = 0
        } else {
            // Horizontal pipe: ellipse is tilted
            rotation = angle * .pi / 180.0
        }

        // Create ellipse
        let rect = CGRect(
            x: center.x - radiusMajor,
            y: center.y - radiusMinor,
            width: radiusMajor * 2,
            height: radiusMinor * 2
        )

        path.addEllipse(in: rect)

        // Rotate if needed
        if rotation != 0 {
            var transform = CGAffineTransform.identity
            transform = transform.translatedBy(x: center.x, y: center.y)
            transform = transform.rotated(by: rotation)
            transform = transform.translatedBy(x: -center.x, y: -center.y)
            path = path.applying(transform)
        }

        return path
    }

    // MARK: - Bolt Hole Rendering

    /// Calculate bolt hole positions on a bolt circle
    func boltHolePositions(center: CGPoint, boltCircleDiameter: Double, holeCount: Int, startAngle: CGFloat = 0) -> [CGPoint] {
        let radius = CGFloat(boltCircleDiameter / 2.0) * scale
        let angleIncrement = (2 * .pi) / CGFloat(holeCount)

        return (0..<holeCount).map { index in
            let angle = startAngle + angleIncrement * CGFloat(index)
            return CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle) * 0.5  // Compressed for isometric
            )
        }
    }

    // MARK: - Pipe Width Calculation

    /// Get the visual width of a pipe at a given angle (for parallel lines)
    /// - Parameters:
    ///   - diameter: Pipe outer diameter in inches
    ///   - angle: Pipe direction angle in degrees
    /// - Returns: Width in points for drawing parallel lines
    func pipeWidth(diameter: Double, angle: CGFloat) -> CGFloat {
        let baseWidth = CGFloat(diameter) * scale

        // In isometric, horizontal pipes show less width than vertical
        if abs(angle - 90) < 15 || abs(angle - 270) < 15 {
            // Vertical pipe: full width visible
            return baseWidth
        } else {
            // Horizontal pipe: foreshortened (30° isometric)
            return baseWidth * sin(30.0 * .pi / 180.0)  // ≈ 0.5 width
        }
    }

    // MARK: - Line Weight Standards

    /// Get standard line width for pipe drawing
    enum LineWeight {
        case visible      // 3-4pt: Visible edges
        case medium       // 2pt: Fitting details
        case hidden       // 1pt dashed: Hidden edges
        case dimension    // 0.5pt: Dimension lines

        func width(zoom: CGFloat = 1.0) -> CGFloat {
            let baseWidth: CGFloat
            switch self {
            case .visible: baseWidth = 3.5
            case .medium: baseWidth = 2.0
            case .hidden: baseWidth = 1.0
            case .dimension: baseWidth = 0.5
            }
            return baseWidth / zoom
        }

        var style: StrokeStyle {
            switch self {
            case .hidden:
                return StrokeStyle(lineWidth: 1.0, lineCap: .round, dash: [5, 3])
            default:
                return StrokeStyle(lineWidth: width(), lineCap: .round, lineJoin: .round)
            }
        }
    }
}

/// Helper to calculate perpendicular offset for parallel lines
extension CGPoint {
    /// Get a point offset perpendicular to a line direction
    func perpendicular(to direction: CGFloat, distance: CGFloat) -> CGPoint {
        let perpAngle = (direction + 90) * .pi / 180.0
        return CGPoint(
            x: x + cos(perpAngle) * distance,
            y: y + sin(perpAngle) * distance
        )
    }
}
