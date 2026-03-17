//
//  SpoolPrintableView.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI
import SwiftData

/// Printable view of spool sheet in 8.5 x 11 landscape format
struct SpoolPrintableView: View {
    @Bindable var spool: Spool
    @Bindable var project: Project
    @Bindable var workPackage: WorkPackage

    // Drawing state with zoom controls
    @State private var pipePoints: [PipePoint] = []
    @State private var viewZoomScale: CGFloat = 1.0  // View zoom scale
    @State private var lastViewZoomScale: CGFloat = 1.0  // For gesture tracking
    @State private var viewPanOffset: CGSize = .zero  // Pan offset for gesture-based panning
    @State private var lastViewPanOffset: CGSize = .zero  // For pan gesture tracking
    @State private var drawingZoomScale: CGFloat = 1.0  // Internal drawing zoom from saved data
    @State private var drawingPanOffset: CGSize = .zero  // Internal drawing pan from saved data
    @State private var centeredOffset: CGSize = .zero  // Calculated center offset

    let scale: CGFloat = 2.0
    let allowedAngles: [CGFloat] = [30, 90, 150, 210, 270, 330]

    // 8.5 x 11 landscape dimensions in points (72 points per inch)
    let pageWidth: CGFloat = 11 * 72  // 792 points
    let pageHeight: CGFloat = 8.5 * 72  // 612 points
    let pageMargin: CGFloat = 20  // Consistent margin around page

    // Content area dimensions (inside margin)
    var contentWidth: CGFloat { pageWidth - (pageMargin * 2) }  // 752 points
    var contentHeight: CGFloat { pageHeight - (pageMargin * 2) }  // 572 points

    // Right panel width for BOM and metadata
    let rightPanelWidth: CGFloat = 190

    // Drawing area dimensions (left side, with small internal margin)
    var drawingAreaWidth: CGFloat { contentWidth - rightPanelWidth - 10 }  // ~552 points
    var drawingAreaHeight: CGFloat { contentHeight }  // 572 points

    var body: some View {
        GeometryReader { geometry in
            let viewWidth = geometry.size.width
            let viewHeight = geometry.size.height
            // Calculate scale to fit page in viewport
            let fitScaleX = (viewWidth * 0.92) / pageWidth
            let fitScaleY = (viewHeight * 0.85) / pageHeight
            let baseFitScale = min(fitScaleX, fitScaleY)
            // Apply user zoom on top of base fit
            let effectiveScale = baseFitScale * viewZoomScale

            ZStack {
                // Background
                Color.gray.opacity(0.2)
                    .ignoresSafeArea()

                // Page content - positioned at center with calculated offset
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        // Left: Drawing area
                        drawingCanvas()
                            .frame(width: drawingAreaWidth, height: drawingAreaHeight)

                        Spacer()
                            .frame(width: 10)

                        // Right: BOM and Metadata
                        VStack(spacing: 10) {
                            // Bill of Materials
                            detailKeyView()
                                .frame(width: rightPanelWidth)
                                .padding(8)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )

                            Spacer()

                            // Project Metadata
                            projectMetadataView()
                                .frame(width: rightPanelWidth)
                                .padding(8)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .frame(height: drawingAreaHeight)
                    }
                    .padding(pageMargin)
                    .background(Color.white)
                    .overlay(
                        // Border around content
                        Rectangle()
                            .stroke(Color.black, lineWidth: 1.5)
                            .padding(pageMargin)
                    )
                }
                .frame(width: pageWidth, height: pageHeight)
                .background(Color.white)
                .clipShape(Rectangle())
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .allowsHitTesting(false)  // Disable interaction on page content
                .scaleEffect(effectiveScale, anchor: .center)
                .offset(viewPanOffset)
                .position(x: viewWidth / 2, y: viewHeight / 2)  // Explicitly center
                .contentShape(Rectangle())  // Make entire area respond to gestures
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let oldZoom = viewZoomScale
                            let newScale = lastViewZoomScale * value
                            viewZoomScale = min(max(newScale, 0.3), 3.0)

                            // Adjust pan offset to keep screen center fixed during zoom
                            let scaleFactor = viewZoomScale / oldZoom
                            viewPanOffset = CGSize(
                                width: viewPanOffset.width * scaleFactor,
                                height: viewPanOffset.height * scaleFactor
                            )
                        }
                        .onEnded { _ in
                            lastViewZoomScale = viewZoomScale
                            lastViewPanOffset = viewPanOffset
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            viewPanOffset = CGSize(
                                width: lastViewPanOffset.width + value.translation.width,
                                height: lastViewPanOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastViewPanOffset = viewPanOffset
                        }
                )

                // Fit to screen button (bottom center)
                VStack {
                    Spacer()
                    Button(action: { resetToFit() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption)
                            Text("Fit to Screen")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(20)
                    }
                    .padding(.bottom, 16)
                }
            }
            .onAppear {
                loadSpool()
                calculateCenteredOffset()
                // Start with zoom at 1.0 (base fit is calculated in view)
                viewZoomScale = 1.0
                lastViewZoomScale = 1.0
                viewPanOffset = .zero
                lastViewPanOffset = .zero
            }
        }
        .navigationTitle("Spool \(spool.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                NavigationLink(destination: SpoolDetailView(spool: spool)) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: printSheet) {
                    Image(systemName: "printer")
                }
            }
        }
    }


    // Drawing canvas with centered spool
    @ViewBuilder
    func drawingCanvas() -> some View {
        GeometryReader { geo in
            drawingCanvasContent(geo: geo)
        }
        .background(Color.white)
        .clipped()
    }

    @ViewBuilder
    private func drawingCanvasContent(geo: GeometryProxy) -> some View {
        ZStack {
            // Background
            Color.white

            pipeSegmentsForPrint
            pointMarkersForPrint
            oletMarkersForPrint
        }
        .frame(width: geo.size.width, height: geo.size.height)
        .scaleEffect(drawingZoomScale, anchor: .center)
        .offset(x: centeredOffset.width, y: centeredOffset.height)
        .overlay(logoOverlay)
    }

    @ViewBuilder
    private var pipeSegmentsForPrint: some View {
        // Main run segments (skip if next point is a branch)
        ForEach(0..<max(0, pipePoints.count - 1), id: \.self) { i in
            // Don't draw segment if the next point is a branch from another tee
            if pipePoints[i + 1].branchParentId == nil {
                ZStack {
                    // Pipe segment
                    PipeSegmentView(
                        segmentIndex: i,
                        start: pipePoints[i].position,
                        end: pipePoints[i + 1].position,
                        scale: scale,
                        zoomScale: drawingZoomScale,
                        measurementType: pipePoints[i].measurementType,
                        pipeSize: pipePoints[i].pipeSize,
                        dimensionLabelOffset: .constant(pipePoints[i].dimensionLabelOffset),
                        sizeLabelOffset: .constant(pipePoints[i].sizeLabelOffset),
                        isDraggingAnyLabel: .constant(false),
                        breakModeEnabled: false,
                        oletModeEnabled: false,
                        onTapMeasurement: { _ in },
                        onTapPipeSize: { _ in },
                        onTapLine: { _, _ in }
                    )

                        // Pipe segment number bubble (midpoint with offset)
                        let midPoint = CGPoint(
                            x: (pipePoints[i].position.x + pipePoints[i + 1].position.x) / 2,
                            y: (pipePoints[i].position.y + pipePoints[i + 1].position.y) / 2
                        )

                        // Calculate actual offset position
                        let segmentOffset = pipePoints[i].segmentBubbleOffset
                        let actualOffset = segmentOffset.map { CGSize(width: $0.width / drawingZoomScale, height: $0.height / drawingZoomScale) } ?? .zero
                        let hasOffset = segmentOffset.map { abs($0.width) > 1 || abs($0.height) > 1 } ?? false

                        // Leader line (if bubble has been moved)
                        if hasOffset {
                            Path { path in
                                path.move(to: midPoint)
                                let labelPoint = CGPoint(
                                    x: midPoint.x + actualOffset.width,
                                    y: midPoint.y + actualOffset.height
                                )
                                let controlPoint = CGPoint(
                                    x: (midPoint.x + labelPoint.x) / 2,
                                    y: (midPoint.y + labelPoint.y) / 2
                                )
                                path.addQuadCurve(to: labelPoint, control: controlPoint)
                            }
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        }

                        Circle()
                            .fill(Color.white)
                            .frame(width: 24 / drawingZoomScale, height: 24 / drawingZoomScale)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2 / drawingZoomScale)
                            )
                            .overlay(
                                Text(indexToLetter(i))
                                    .font(.system(size: 12 / drawingZoomScale, weight: .bold))
                                    .foregroundColor(.blue)
                            )
                            .position(
                                x: midPoint.x + actualOffset.width,
                                y: midPoint.y + actualOffset.height
                            )
                    }
                }
            }

        // Branch segments (from parent tees to branch points)
        ForEach(Array(pipePoints.enumerated()), id: \.offset) { index, pipePoint in
            if let parentId = pipePoint.branchParentId,
               let parentIndex = pipePoints.firstIndex(where: { $0.id == parentId }) {
                let midPoint = CGPoint(
                    x: (pipePoints[parentIndex].position.x + pipePoint.position.x) / 2,
                    y: (pipePoints[parentIndex].position.y + pipePoint.position.y) / 2
                )

                PipeSegmentView(
                    segmentIndex: index,
                    start: pipePoints[parentIndex].position,
                    end: pipePoint.position,
                    scale: scale,
                    zoomScale: drawingZoomScale,
                    measurementType: pipePoint.measurementType,
                    pipeSize: pipePoint.pipeSize,
                    dimensionLabelOffset: .constant(pipePoint.branchDimensionLabelOffset),
                    sizeLabelOffset: .constant(pipePoint.branchSizeLabelOffset),
                    isDraggingAnyLabel: .constant(false),
                    breakModeEnabled: false,
                    oletModeEnabled: false,
                    onTapMeasurement: { _ in },
                    onTapPipeSize: { _ in },
                    onTapLine: { _, _ in }
                )

                // Branch segment bubble
                let segmentOffset = pipePoint.branchSegmentBubbleOffset
                let actualOffset = segmentOffset.map { CGSize(width: $0.width / drawingZoomScale, height: $0.height / drawingZoomScale) } ?? .zero
                let hasOffset = segmentOffset.map { abs($0.width) > 1 || abs($0.height) > 1 } ?? false

                if hasOffset {
                    Path { path in
                        path.move(to: midPoint)
                        let labelPoint = CGPoint(
                            x: midPoint.x + actualOffset.width,
                            y: midPoint.y + actualOffset.height
                        )
                        let controlPoint = CGPoint(
                            x: (midPoint.x + labelPoint.x) / 2,
                            y: (midPoint.y + labelPoint.y) / 2
                        )
                        path.addQuadCurve(to: labelPoint, control: controlPoint)
                    }
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                }

                Circle()
                    .fill(Color.white)
                    .frame(width: 24 / drawingZoomScale, height: 24 / drawingZoomScale)
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 2 / drawingZoomScale)
                    )
                    .overlay(
                        Text(indexToLetter(index))
                            .font(.system(size: 12 / drawingZoomScale, weight: .bold))
                            .foregroundColor(.blue)
                    )
                    .position(
                        x: midPoint.x + actualOffset.width,
                        y: midPoint.y + actualOffset.height
                    )
            }
        }
    }

    @ViewBuilder
    private var pointMarkersForPrint: some View {
        ForEach(Array(pipePoints.enumerated()), id: \.offset) { index, pipePoint in
            let pointHasBranch = pipePoints.contains(where: { $0.branchParentId == pipePoint.id })

            PointMarkerView(
                index: index,
                isFirst: index == 0,
                isLast: index == pipePoints.count - 1,
                fittingType: pipePoint.fittingType,
                fittingOrientation: pipePoint.fittingOrientation,
                hasBranch: pointHasBranch,
                position: pipePoint.position,
                zoomScale: drawingZoomScale,
                bubbleLabelOffset: .constant(pipePoint.bubbleLabelOffset),
                isDraggingAnyLabel: .constant(false),
                onTap: {}
            )
        }
    }

    @ViewBuilder
    private var oletMarkersForPrint: some View {
        // O'lets on main run segments
        ForEach(0..<max(0, pipePoints.count - 1), id: \.self) { i in
            if pipePoints[i + 1].branchParentId == nil {
                ForEach(Array(pipePoints[i].olets.indices), id: \.self) { oletIndex in
                    OletMarkerView(
                        olet: pipePoints[i].olets[oletIndex],
                        segmentStart: pipePoints[i].position,
                        segmentEnd: pipePoints[i + 1].position,
                        zoomScale: drawingZoomScale,
                        scale: scale,
                        identifier: oletIdentifier(segmentIndex: i, oletIndex: oletIndex),
                        dimensionLabelOffset: .constant(pipePoints[i].olets[oletIndex].dimensionLabelOffset),
                        isDraggingAnyLabel: .constant(false),
                        onTap: {},
                        onTapDimension: {}
                    )
                }
            }
        }

        // O'lets on branch segments
        ForEach(Array(pipePoints.enumerated()), id: \.offset) { index, pipePoint in
            if let parentId = pipePoint.branchParentId,
               let parentIndex = pipePoints.firstIndex(where: { $0.id == parentId }) {
                ForEach(Array(pipePoints[parentIndex].olets.indices), id: \.self) { oletIndex in
                    OletMarkerView(
                        olet: pipePoints[parentIndex].olets[oletIndex],
                        segmentStart: pipePoints[parentIndex].position,
                        segmentEnd: pipePoint.position,
                        zoomScale: drawingZoomScale,
                        scale: scale,
                        identifier: oletIdentifier(segmentIndex: parentIndex, oletIndex: oletIndex),
                        dimensionLabelOffset: .constant(pipePoints[parentIndex].olets[oletIndex].dimensionLabelOffset),
                        isDraggingAnyLabel: .constant(false),
                        onTap: {},
                        onTapDimension: {}
                    )
                }
            }
        }
    }

    private var logoOverlay: some View {
        VStack {
            Spacer()
            HStack {
                BrandingView(size: 40)
                    .scaleEffect(1.0 / drawingZoomScale)
                Spacer()
            }
        }
        .padding(8)
    }

    // Fitting item for BOM
    struct FittingItem: Identifiable {
        let id = UUID()
        let fittingType: FittingType
        let enteringSize: PipeSize?
        let exitingSize: PipeSize?
        let branchSize: PipeSize?  // For tees: the branch outlet size
        let pointIndex: Int
        let isInferred: Bool
    }

    // Pipe length item for BOM
    struct PipeLengthItem: Identifiable {
        let id = UUID()
        let pipeSize: PipeSize
        let totalLength: CGFloat
    }

    // O'let item for BOM
    struct OletItem: Identifiable {
        let id = UUID()
        let oletType: OletType
        let pipeSize: PipeSize
        let outletSize: PipeSize
        let segmentIndex: Int
        let identifier: String  // Sequential identifier like "O1", "O2", etc.
    }

    var fittingItems: [FittingItem] {
        var items: [FittingItem] = []

        for (index, point) in pipePoints.enumerated() {
            let isFirst = index == 0
            let isLast = index == pipePoints.count - 1

            let enteringSize: PipeSize? = isFirst ? nil : pipePoints[index - 1].pipeSize
            let exitingSize: PipeSize? = isLast ? nil : pipePoints[index].pipeSize

            // Explicit fittings
            if point.fittingType != .none {
                // For tees, detect the branch size
                var branchSize: PipeSize? = nil
                if point.fittingType == .tee {
                    // Find branch point connected to this tee
                    if let branchPoint = pipePoints.first(where: { $0.branchParentId == point.id }) {
                        branchSize = branchPoint.pipeSize
                    }
                }

                items.append(FittingItem(
                    fittingType: point.fittingType,
                    enteringSize: enteringSize,
                    exitingSize: exitingSize,
                    branchSize: branchSize,
                    pointIndex: index,
                    isInferred: false
                ))
            }
            // Inferred elbows from direction changes
            else if !isFirst && !isLast {
                let prevPoint = pipePoints[index - 1].position
                let currentPoint = point.position
                let nextPoint = pipePoints[index + 1].position

                let incomingAngle = segmentAngle(from: prevPoint, to: currentPoint)
                let outgoingAngle = segmentAngle(from: currentPoint, to: nextPoint)
                let turn = turnAngle(incomingAngle: incomingAngle, outgoingAngle: outgoingAngle)

                let inferredType = inferredElbowType(turnAngle: turn)
                if inferredType != .none {
                    items.append(FittingItem(
                        fittingType: inferredType,
                        enteringSize: enteringSize,
                        exitingSize: exitingSize,
                        branchSize: nil,
                        pointIndex: index,
                        isInferred: true
                    ))
                }
            }
        }
        return items
    }

    var pipeLengthItems: [PipeLengthItem] {
        var lengthsBySize: [PipeSize: CGFloat] = [:]

        for i in 0..<(pipePoints.count - 1) {
            let start = pipePoints[i].position
            let end = pipePoints[i + 1].position
            let length = segmentLength(from: start, to: end)

            let size = pipePoints[i].pipeSize
            lengthsBySize[size, default: 0] += length
        }

        return PipeSize.allCases.compactMap { size in
            guard let length = lengthsBySize[size], length > 0 else { return nil }
            return PipeLengthItem(pipeSize: size, totalLength: length)
        }
    }

    var totalPipeLength: CGFloat {
        pipeLengthItems.reduce(0) { $0 + $1.totalLength }
    }

    var oletItems: [OletItem] {
        var items: [OletItem] = []
        var count = 1

        for (index, point) in pipePoints.enumerated() {
            let pipeSize = point.pipeSize

            for olet in point.olets {
                items.append(OletItem(
                    oletType: olet.type,
                    pipeSize: pipeSize,
                    outletSize: olet.size,
                    segmentIndex: index,
                    identifier: "O\(count)"
                ))
                count += 1
            }
        }

        return items
    }

    /// Get the sequential identifier for an o'let (e.g., "O1", "O2", etc.)
    func oletIdentifier(segmentIndex: Int, oletIndex: Int) -> String {
        var count = 1

        for (pointIndex, point) in pipePoints.enumerated() {
            for (oIndex, _) in point.olets.enumerated() {
                if pointIndex == segmentIndex && oIndex == oletIndex {
                    return "O\(count)"
                }
                count += 1
            }
        }

        return "O?"
    }

    func segmentAngle(from start: CGPoint, to end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        var angle = atan2(-dy, dx) * 180 / .pi
        if angle < 0 { angle += 360 }
        return angle
    }

    func turnAngle(incomingAngle: CGFloat, outgoingAngle: CGFloat) -> CGFloat {
        var diff = outgoingAngle - incomingAngle
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return abs(diff)
    }

    func inferredElbowType(turnAngle: CGFloat) -> FittingType {
        if turnAngle < 10 {
            return .none
        } else if turnAngle >= 10 && turnAngle <= 135 {
            return .elbow90
        } else {
            return .elbow90
        }
    }

    func formatFittingSize(_ item: FittingItem) -> String {
        let entering = item.enteringSize?.shortName ?? "—"
        let exiting = item.exitingSize?.shortName ?? "—"
        let branch = item.branchSize?.shortName

        // Tees with branch size show: entering × exiting × branch
        if item.fittingType == .tee, let branchSize = branch {
            if item.enteringSize == item.exitingSize && item.enteringSize?.shortName == branchSize {
                return branchSize  // All same size
            } else if item.enteringSize == item.exitingSize {
                return "\(entering)×\(branchSize)"  // Run same, branch different
            } else {
                return "\(entering)×\(exiting)×\(branchSize)"  // All different
            }
        }

        if item.enteringSize == nil {
            return exiting
        } else if item.exitingSize == nil {
            return entering
        }

        if item.enteringSize == item.exitingSize {
            return entering
        } else {
            return "\(entering)×\(exiting)"
        }
    }

    // Detail key in upper right - Table format with number tags
    @ViewBuilder
    func detailKeyView() -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Bill of Materials")
                .font(.system(size: 10, weight: .bold))
                .padding(.bottom, 1)

            Divider()

            if pipePoints.isEmpty {
                Text("No data")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        // Header row
                        HStack(spacing: 3) {
                            Text("Tag")
                                .font(.system(size: 7, weight: .bold))
                                .frame(width: 24, alignment: .center)
                            Text("Description")
                                .font(.system(size: 7, weight: .bold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Size")
                                .font(.system(size: 7, weight: .bold))
                                .frame(width: 26, alignment: .center)
                            Text("Type")
                                .font(.system(size: 7, weight: .bold))
                                .frame(width: 28, alignment: .center)
                            Text("Length")
                                .font(.system(size: 7, weight: .bold))
                                .frame(width: 38, alignment: .trailing)
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                        .background(Color.gray.opacity(0.15))

                        Divider()

                        // Data rows - Points and Pipes
                        ForEach(Array(pipePoints.enumerated()), id: \.offset) { index, point in
                            // Point row with fitting
                            HStack(spacing: 3) {
                                // Point number tag
                                ZStack {
                                    Circle()
                                        .fill(pointColor(index: index, point: point))
                                        .frame(width: 14, height: 14)
                                    Text("\(index + 1)")
                                        .font(.system(size: 6, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 24, alignment: .center)

                                // Fitting description and size
                                let fittingItem = fittingItems.first(where: { $0.pointIndex == index })

                                VStack(alignment: .leading, spacing: 0) {
                                    if point.fittingType != .none {
                                        Text(point.fittingType.rawValue)
                                            .font(.system(size: 7))
                                            .lineLimit(1)
                                    } else {
                                        // Check for inferred elbow
                                        if let inferredFitting = fittingItem, inferredFitting.isInferred {
                                            Text(inferredFitting.fittingType.rawValue + "*")
                                                .font(.system(size: 7))
                                                .foregroundColor(.orange)
                                                .lineLimit(1)
                                        } else {
                                            Text("Point")
                                                .font(.system(size: 7))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                // Fitting size
                                if let fitting = fittingItem {
                                    Text(formatFittingSize(fitting))
                                        .font(.system(size: 7))
                                        .frame(width: 26, alignment: .center)
                                } else {
                                    Text("—")
                                        .font(.system(size: 7))
                                        .frame(width: 26, alignment: .center)
                                        .foregroundColor(.secondary)
                                }

                                // Fitting type (explicit vs inferred)
                                if let fitting = fittingItem {
                                    Text(fitting.isInferred ? "Inf" : "Exp")
                                        .font(.system(size: 7))
                                        .frame(width: 28, alignment: .center)
                                        .foregroundColor(fitting.isInferred ? .orange : .primary)
                                } else {
                                    Text("—")
                                        .font(.system(size: 7))
                                        .frame(width: 28, alignment: .center)
                                        .foregroundColor(.secondary)
                                }

                                // Empty length for point
                                Text("—")
                                    .font(.system(size: 7))
                                    .frame(width: 38, alignment: .trailing)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 1)
                            .padding(.horizontal, 4)

                            // Pipe segment row (if not last point)
                            if index < pipePoints.count - 1 {
                                HStack(spacing: 3) {
                                    // Pipe number tag (blue bubble)
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 14, height: 14)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.blue, lineWidth: 1.2)
                                            )
                                        Text(indexToLetter(index))
                                            .font(.system(size: 6, weight: .bold))
                                            .foregroundColor(.blue)
                                    }
                                    .frame(width: 24, alignment: .center)

                                    // Pipe description (no size)
                                    Text("Pipe")
                                        .font(.system(size: 7))
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    // Pipe size
                                    let size = point.pipeSize
                                    Text(size == .none ? "—" : size.shortName)
                                        .font(.system(size: 7))
                                        .frame(width: 26, alignment: .center)

                                    // Measurement type
                                    Text(point.measurementType ?? "—")
                                        .font(.system(size: 7))
                                        .frame(width: 28, alignment: .center)

                                    // Pipe length
                                    let length = segmentLength(from: point.position, to: pipePoints[index + 1].position)
                                    Text(formatFeetInches(inches: length))
                                        .font(.system(size: 7, weight: .medium))
                                        .frame(width: 38, alignment: .trailing)
                                }
                                .padding(.vertical, 1)
                                .padding(.horizontal, 4)
                                .background(Color.blue.opacity(0.05))

                                // O'let rows (if any on this segment)
                                ForEach(Array(point.olets.enumerated()), id: \.offset) { oletIdx, olet in
                                    HStack(spacing: 3) {
                                        // O'let identifier tag (purple badge)
                                        Text(oletIdentifier(segmentIndex: index, oletIndex: oletIdx))
                                            .font(.system(size: 6, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.purple)
                                            .cornerRadius(3)
                                            .frame(width: 24, alignment: .center)

                                        // O'let description
                                        Text(olet.type.rawValue)
                                            .font(.system(size: 7))
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        // O'let size (pipe × outlet)
                                        Text("\(point.pipeSize.shortName)×\(olet.size.shortName)")
                                            .font(.system(size: 7))
                                            .frame(width: 26, alignment: .center)

                                        // Empty type field
                                        Text("—")
                                            .font(.system(size: 7))
                                            .frame(width: 28, alignment: .center)
                                            .foregroundColor(.secondary)

                                        // Empty length field
                                        Text("—")
                                            .font(.system(size: 7))
                                            .frame(width: 38, alignment: .trailing)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 1)
                                    .padding(.horizontal, 4)
                                    .background(Color.purple.opacity(0.05))
                                }
                            }

                            if index < pipePoints.count - 1 {
                                Divider()
                            }
                        }

                        // Total row
                        if !pipePoints.isEmpty && pipePoints.count > 1 {
                            HStack(spacing: 3) {
                                Text("Total")
                                    .font(.system(size: 7, weight: .bold))
                                    .frame(width: 24, alignment: .leading)

                                Spacer()

                                Text("")
                                    .frame(width: 26, alignment: .center)

                                Text("")
                                    .frame(width: 28, alignment: .center)

                                Text(formatFeetInches(inches: totalPipeLength))
                                    .font(.system(size: 7, weight: .bold))
                                    .frame(width: 38, alignment: .trailing)
                            }
                            .padding(.vertical, 2)
                            .padding(.horizontal, 4)
                            .background(Color.gray.opacity(0.2))
                        }
                    }
                }
            }
        }
    }

    // Project metadata in bottom right - vertical table format
    @ViewBuilder
    func projectMetadataView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Project info
            HStack {
                Text("Project:")
                    .font(.system(size: 8, weight: .semibold))
                Spacer()
                Text(project.name)
                    .font(.system(size: 8))
                    .lineLimit(1)
            }

            HStack {
                Text("Job:")
                    .font(.system(size: 8, weight: .semibold))
                Spacer()
                Text(project.jobNumber)
                    .font(.system(size: 8))
            }

            Divider()

            // Work package info
            HStack {
                Text("Package:")
                    .font(.system(size: 8, weight: .semibold))
                Spacer()
                Text(workPackage.name)
                    .font(.system(size: 8))
                    .lineLimit(1)
            }

            HStack {
                Text("PKG#:")
                    .font(.system(size: 8, weight: .semibold))
                Spacer()
                Text(workPackage.packageNumber)
                    .font(.system(size: 8))
            }

            Divider()

            // Spool info
            HStack {
                Text("Spool:")
                    .font(.system(size: 8, weight: .semibold))
                Spacer()
                Text(spool.name)
                    .font(.system(size: 8))
                    .lineLimit(1)
            }

            if let systemType = spool.systemType {
                HStack {
                    Text("System:")
                        .font(.system(size: 8, weight: .semibold))
                    Spacer()
                    Text(systemType)
                        .font(.system(size: 8))
                        .lineLimit(1)
                }
            }

            HStack {
                Text("Status:")
                    .font(.system(size: 8, weight: .semibold))
                Spacer()
                Text(spool.status)
                    .font(.system(size: 8))
            }

            HStack {
                Text("Date:")
                    .font(.system(size: 8, weight: .semibold))
                Spacer()
                Text(spool.modifiedDate, style: .date)
                    .font(.system(size: 8))
            }
        }
    }

    // MARK: - Helper Functions

    func loadSpool() {
        pipePoints = spool.pipePoints
        // Always start with base zoom, will be adjusted by calculateCenteredOffset
        drawingZoomScale = 1.0
        // Ignore saved pan offset - we'll center based on bounding box only
        drawingPanOffset = .zero
    }

    func calculateCenteredOffset() {
        guard !pipePoints.isEmpty else {
            centeredOffset = .zero
            return
        }

        // Calculate bounding box of all points
        var minX = pipePoints[0].position.x
        var maxX = pipePoints[0].position.x
        var minY = pipePoints[0].position.y
        var maxY = pipePoints[0].position.y

        for point in pipePoints {
            minX = min(minX, point.position.x)
            maxX = max(maxX, point.position.x)
            minY = min(minY, point.position.y)
            maxY = max(maxY, point.position.y)
        }

        // Calculate center of bounding box
        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2

        // Calculate the size of the bounding box before scaling
        let bboxWidth = (maxX - minX)
        let bboxHeight = (maxY - minY)

        // Calculate scale to fit in drawing area (80% to leave margin)
        let targetWidth = drawingAreaWidth * 0.8 / drawingZoomScale
        let targetHeight = drawingAreaHeight * 0.8 / drawingZoomScale

        if bboxWidth > 0 && bboxHeight > 0 {
            let scaleX = targetWidth / bboxWidth
            let scaleY = targetHeight / bboxHeight
            let fitScale = min(scaleX, scaleY, 1.0) // Don't scale up, only down if needed

            if fitScale < 1.0 {
                drawingZoomScale = drawingZoomScale * fitScale
            }
        }

        // Center offset: move the bounding box center to the drawing area center
        // Drawing area center is at (drawingAreaWidth/2, drawingAreaHeight/2)
        centeredOffset = CGSize(
            width: drawingAreaWidth / 2 - centerX * drawingZoomScale,
            height: drawingAreaHeight / 2 - centerY * drawingZoomScale
        )
    }

    func pointColor(index: Int, point: PipePoint) -> Color {
        if index == 0 { return .green }
        if index == pipePoints.count - 1 { return .red }
        if point.fittingType != .none { return .blue }
        return .orange
    }

    func resetToFit() {
        // Reset zoom and pan to default (fit is calculated in view body)
        withAnimation(.easeInOut(duration: 0.3)) {
            viewZoomScale = 1.0
            lastViewZoomScale = 1.0
            viewPanOffset = .zero
            lastViewPanOffset = .zero
        }
    }

    func directionLabel(from start: CGPoint, to end: CGPoint) -> String {
        let dx = end.x - start.x
        let dy = end.y - start.y
        var angle = atan2(-dy, dx) * 180 / .pi
        if angle < 0 { angle += 360 }

        let tolerance: CGFloat = 15
        if angleDifference(angle, 30) < tolerance { return "NW" }
        if angleDifference(angle, 90) < tolerance { return "Up" }
        if angleDifference(angle, 150) < tolerance { return "NE" }
        if angleDifference(angle, 210) < tolerance { return "SE" }
        if angleDifference(angle, 270) < tolerance { return "Down" }
        if angleDifference(angle, 330) < tolerance { return "SW" }
        return ""
    }

    func angleDifference(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        var diff = abs(a - b)
        if diff > 180 { diff = 360 - diff }
        return diff
    }

    func segmentLength(from start: CGPoint, to end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        return sqrt(dx * dx + dy * dy) / scale
    }

    func printSheet() {
        // TODO: Implement printing functionality
        print("Print sheet requested for spool: \(spool.name)")
    }
}

#Preview {
    NavigationStack {
        SpoolPrintableView(
            spool: Spool(
                name: "2026-001-001",
                systemType: SystemType.hotWater.rawValue,
                status: "Draft"
            ),
            project: Project(
                name: "Office Building",
                jobNumber: "2026"
            ),
            workPackage: WorkPackage(
                name: "Ground Floor",
                packageNumber: "001",
                status: "In Progress"
            )
        )
    }
    .modelContainer(DataController.shared.container)
}
