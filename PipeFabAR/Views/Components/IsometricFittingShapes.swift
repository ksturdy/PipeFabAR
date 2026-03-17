//
//  IsometricFittingShapes.swift
//  PipeFabAR
//
//  Created by Claude on 2026-02-15.
//  Isometric shapes for accurate pipe fitting rendering
//

import SwiftUI

// MARK: - Flange Shape

/// Renders a flange in isometric projection with bolt holes
struct IsometricFlangeShape: Shape {
    let center: CGPoint
    let pipeSize: PipeSize
    let angle: CGFloat  // Pipe direction angle
    let rating: FlangeRating
    let scale: CGFloat
    let showBoltHoles: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let renderer = IsometricRenderer(scale: scale)
        let dimensions = pipeSize.flangeDimensions(rating: rating)

        // Determine if flange faces viewer or is edge-on
        let isVerticalPipe = abs(angle - 90) < 15 || abs(angle - 270) < 15

        if isVerticalPipe {
            // Vertical pipe: flange is horizontal (shows as ellipse)
            path.addPath(drawHorizontalFlange(center: center, dimensions: dimensions, renderer: renderer))
        } else {
            // Horizontal pipe: flange is vertical (shows as circle/ellipse)
            path.addPath(drawVerticalFlange(center: center, dimensions: dimensions, angle: angle, renderer: renderer))
        }

        return path
    }

    /// Draw flange on horizontal pipe (appears as ellipse)
    private func drawHorizontalFlange(center: CGPoint, dimensions: FlangeDimensions, renderer: IsometricRenderer) -> Path {
        var path = Path()

        let outerRadius = CGFloat(dimensions.outerDiameter / 2.0) * scale
        let raisedFaceRadius = CGFloat(dimensions.raisedFaceDiameter / 2.0) * scale
        let boltCircleRadius = CGFloat(dimensions.boltCircleDiameter / 2.0) * scale

        // Isometric ellipse compression factor (30°)
        let compression: CGFloat = 0.5

        // Outer flange circle (as ellipse in isometric)
        let outerRect = CGRect(
            x: center.x - outerRadius,
            y: center.y - outerRadius * compression,
            width: outerRadius * 2,
            height: outerRadius * 2 * compression
        )
        path.addEllipse(in: outerRect)

        // Raised face (inner circle)
        let raisedFaceRect = CGRect(
            x: center.x - raisedFaceRadius,
            y: center.y - raisedFaceRadius * compression,
            width: raisedFaceRadius * 2,
            height: raisedFaceRadius * 2 * compression
        )
        path.addEllipse(in: raisedFaceRect)

        // Bolt holes
        if showBoltHoles {
            let boltHoleRadius = CGFloat(dimensions.boltHoleDiameter / 2.0) * scale
            let angleIncrement = (2 * .pi) / CGFloat(dimensions.boltHoleCount)

            for i in 0..<dimensions.boltHoleCount {
                let holeAngle = angleIncrement * CGFloat(i)
                let holeX = center.x + boltCircleRadius * cos(holeAngle)
                let holeY = center.y + boltCircleRadius * sin(holeAngle) * compression

                let holeRect = CGRect(
                    x: holeX - boltHoleRadius,
                    y: holeY - boltHoleRadius * compression,
                    width: boltHoleRadius * 2,
                    height: boltHoleRadius * 2 * compression
                )
                path.addEllipse(in: holeRect)
            }
        }

        return path
    }

    /// Draw flange on vertical pipe (appears more circular)
    private func drawVerticalFlange(center: CGPoint, dimensions: FlangeDimensions, angle: CGFloat, renderer: IsometricRenderer) -> Path {
        var path = Path()

        let outerRadius = CGFloat(dimensions.outerDiameter / 2.0) * scale
        let raisedFaceRadius = CGFloat(dimensions.raisedFaceDiameter / 2.0) * scale
        let boltCircleRadius = CGFloat(dimensions.boltCircleDiameter / 2.0) * scale

        // Outer flange circle
        path.addEllipse(in: CGRect(
            x: center.x - outerRadius,
            y: center.y - outerRadius,
            width: outerRadius * 2,
            height: outerRadius * 2
        ))

        // Raised face
        path.addEllipse(in: CGRect(
            x: center.x - raisedFaceRadius,
            y: center.y - raisedFaceRadius,
            width: raisedFaceRadius * 2,
            height: raisedFaceRadius * 2
        ))

        // Bolt holes
        if showBoltHoles {
            let boltHoleRadius = CGFloat(dimensions.boltHoleDiameter / 2.0) * scale
            let angleIncrement = (2 * .pi) / CGFloat(dimensions.boltHoleCount)

            for i in 0..<dimensions.boltHoleCount {
                let holeAngle = angleIncrement * CGFloat(i)
                let holeX = center.x + boltCircleRadius * cos(holeAngle)
                let holeY = center.y + boltCircleRadius * sin(holeAngle)

                path.addEllipse(in: CGRect(
                    x: holeX - boltHoleRadius,
                    y: holeY - boltHoleRadius,
                    width: boltHoleRadius * 2,
                    height: boltHoleRadius * 2
                ))
            }
        }

        return path
    }
}

// MARK: - Pipe Cylinder Shape

/// Renders a pipe as an isometric cylinder with visible top surface
struct IsometricPipeCylinderShape: Shape {
    let start: CGPoint
    let end: CGPoint
    let pipeSize: PipeSize
    let angle: CGFloat
    let scale: CGFloat
    let showEndCaps: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let renderer = IsometricRenderer(scale: scale)
        let diameter = pipeSize.outerDiameter
        let halfWidth = renderer.pipeWidth(diameter: diameter, angle: angle) / 2

        // Calculate perpendicular offset for parallel lines
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = sqrt(dx * dx + dy * dy)

        guard length > 0 else { return path }

        let perpX = -dy / length * halfWidth
        let perpY = dx / length * halfWidth

        // Top edge of pipe
        let topStart = CGPoint(x: start.x + perpX, y: start.y + perpY)
        let topEnd = CGPoint(x: end.x + perpX, y: end.y + perpY)

        // Bottom edge of pipe
        let bottomStart = CGPoint(x: start.x - perpX, y: start.y - perpY)
        let bottomEnd = CGPoint(x: end.x - perpX, y: end.y - perpY)

        // Draw parallel lines for pipe sides
        path.move(to: topStart)
        path.addLine(to: topEnd)
        path.move(to: bottomStart)
        path.addLine(to: bottomEnd)

        // Add end caps (ellipses) if requested
        if showEndCaps {
            // Near end (start)
            path.addPath(renderer.ellipse(at: start, diameter: diameter, angle: angle))

            // Far end (end)
            path.addPath(renderer.ellipse(at: end, diameter: diameter, angle: angle))
        }

        return path
    }
}

// MARK: - Elbow Shape

/// Renders a 90° elbow with proper curved transition
struct IsometricElbowShape: Shape {
    let center: CGPoint
    let pipeSize: PipeSize
    let fromAngle: CGFloat  // Incoming pipe direction
    let toAngle: CGFloat    // Outgoing pipe direction
    let scale: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let renderer = IsometricRenderer(scale: scale)
        let fittingDim = FittingType.elbow90.centerToFace(pipeSize: pipeSize)
        let radius = CGFloat(fittingDim) * scale

        // Calculate start and end points of the curve
        let startAngle = fromAngle * .pi / 180
        let endAngle = toAngle * .pi / 180

        // Draw curved outer edge
        let arcCenter = center
        path.addArc(
            center: arcCenter,
            radius: radius,
            startAngle: Angle(radians: startAngle),
            endAngle: Angle(radians: endAngle),
            clockwise: false
        )

        // Draw curved inner edge (smaller radius)
        let innerRadius = radius * 0.7
        path.move(to: CGPoint(
            x: center.x + innerRadius * cos(startAngle),
            y: center.y + innerRadius * sin(startAngle)
        ))
        path.addArc(
            center: arcCenter,
            radius: innerRadius,
            startAngle: Angle(radians: startAngle),
            endAngle: Angle(radians: endAngle),
            clockwise: false
        )

        return path
    }
}

// MARK: - Tee Shape

/// Renders a tee fitting with three-way junction
struct IsometricTeeShape: Shape {
    let center: CGPoint
    let pipeSize: PipeSize
    let runAngle: CGFloat       // Main run direction
    let branchAngle: CGFloat    // Branch outlet direction
    let scale: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let renderer = IsometricRenderer(scale: scale)
        let diameter = pipeSize.outerDiameter
        let halfWidth = renderer.pipeWidth(diameter: diameter, angle: runAngle) / 2
        let centerToEnd = CGFloat(FittingType.tee.centerToFace(pipeSize: pipeSize)) * scale

        // Draw main body as circle/ellipse
        let bodyRadius = halfWidth * 1.5
        path.addEllipse(in: CGRect(
            x: center.x - bodyRadius,
            y: center.y - bodyRadius,
            width: bodyRadius * 2,
            height: bodyRadius * 2
        ))

        // Draw branch outlet indicator
        let branchRad = branchAngle * .pi / 180
        let branchLength = centerToEnd * 0.4
        let branchEnd = CGPoint(
            x: center.x + branchLength * cos(branchRad),
            y: center.y + branchLength * sin(branchRad)
        )

        path.move(to: center)
        path.addLine(to: branchEnd)

        return path
    }
}

// MARK: - Valve Shape

/// Renders a valve body in isometric projection
struct IsometricValveShape: Shape {
    let center: CGPoint
    let pipeSize: PipeSize
    let valveType: ValveType
    let angle: CGFloat
    let scale: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let dimensions = pipeSize.valveDimensions(valveType: valveType)

        let bodyWidth = CGFloat(dimensions.bodyWidth) * scale
        let bodyHeight = CGFloat(dimensions.bodyHeight) * scale

        // Draw valve body as rectangle
        let bodyRect = CGRect(
            x: center.x - bodyWidth / 2,
            y: center.y - bodyHeight / 2,
            width: bodyWidth,
            height: bodyHeight
        )
        path.addRect(bodyRect)

        // Add valve-specific details
        switch valveType {
        case .ball, .plug:
            // Add circular indicator in center
            path.addEllipse(in: CGRect(
                x: center.x - bodyWidth / 4,
                y: center.y - bodyWidth / 4,
                width: bodyWidth / 2,
                height: bodyWidth / 2
            ))
        case .gate, .globe:
            // Add handwheel on top
            let wheelRadius = bodyWidth / 3
            path.addEllipse(in: CGRect(
                x: center.x - wheelRadius,
                y: center.y - bodyHeight / 2 - wheelRadius,
                width: wheelRadius * 2,
                height: wheelRadius * 2
            ))
        default:
            break
        }

        return path
    }
}

// MARK: - Reducer Shape

/// Renders a concentric or eccentric reducer
struct IsometricReducerShape: Shape {
    let start: CGPoint
    let end: CGPoint
    let largePipeSize: PipeSize
    let smallPipeSize: PipeSize
    let angle: CGFloat
    let scale: CGFloat
    let isEccentric: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let renderer = IsometricRenderer(scale: scale)

        let largeHalfWidth = renderer.pipeWidth(diameter: largePipeSize.outerDiameter, angle: angle) / 2
        let smallHalfWidth = renderer.pipeWidth(diameter: smallPipeSize.outerDiameter, angle: angle) / 2

        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = sqrt(dx * dx + dy * dy)

        guard length > 0 else { return path }

        let perpX = -dy / length
        let perpY = dx / length

        // Large end
        let largeTop = CGPoint(
            x: start.x + perpX * largeHalfWidth,
            y: start.y + perpY * largeHalfWidth
        )
        let largeBottom = CGPoint(
            x: start.x - perpX * largeHalfWidth,
            y: start.y - perpY * largeHalfWidth
        )

        // Small end
        let smallTop = CGPoint(
            x: end.x + perpX * smallHalfWidth,
            y: end.y + perpY * smallHalfWidth
        )
        let smallBottom = CGPoint(
            x: end.x - perpX * smallHalfWidth,
            y: end.y - perpY * smallHalfWidth
        )

        // Draw tapered sides
        path.move(to: largeTop)
        path.addLine(to: smallTop)
        path.move(to: largeBottom)
        path.addLine(to: smallBottom)

        // Draw end caps
        path.addPath(renderer.ellipse(at: start, diameter: largePipeSize.outerDiameter, angle: angle))
        path.addPath(renderer.ellipse(at: end, diameter: smallPipeSize.outerDiameter, angle: angle))

        return path
    }
}
