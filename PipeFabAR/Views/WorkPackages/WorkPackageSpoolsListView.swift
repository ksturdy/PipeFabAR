//
//  WorkPackageSpoolsListView.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI
import SwiftData
import MessageUI

/// List view showing all spools in a work package with move/manage options
struct WorkPackageSpoolsListView: View {
    @Bindable var workPackage: WorkPackage
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var spoolToView: Spool? = nil
    @State private var spoolToEdit: Spool? = nil
    @State private var spoolToMove: Spool? = nil
    @State private var spoolToEmail: Spool? = nil
    @State private var showingMailError = false

    var body: some View {
        NavigationStack {
            List {
                if workPackage.assignedSpools.isEmpty {
                    ContentUnavailableView(
                        "No Spools",
                        systemImage: "cylinder.fill",
                        description: Text("Create spools for this work package")
                    )
                } else {
                    ForEach(workPackage.assignedSpools) { spool in
                        HStack {
                            // Spool info - tappable to edit
                            Button {
                                spoolToEdit = spool
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(spool.name)
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    HStack(spacing: 8) {
                                        Text(spool.status)
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        if let systemType = spool.systemType {
                                            Text(systemType)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            // View sheet button
                            Button {
                                spoolToView = spool
                            } label: {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)

                            // Move button
                            Button {
                                spoolToMove = spool
                            } label: {
                                Image(systemName: "arrow.right.circle")
                                    .font(.title3)
                                    .foregroundColor(.orange)
                            }
                            .buttonStyle(.plain)

                            // Email button
                            Button {
                                if MFMailComposeViewController.canSendMail() {
                                    spoolToEmail = spool
                                } else {
                                    showingMailError = true
                                }
                            } label: {
                                Image(systemName: "envelope.circle")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                            }
                            .buttonStyle(.plain)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteSpool(spool)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("\(workPackage.name) Spools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $spoolToMove) { spool in
                MoveSpoolSheet(spool: spool, project: project, currentPackage: workPackage)
            }
            .navigationDestination(item: $spoolToView) { spool in
                SpoolPrintableView(spool: spool, project: project, workPackage: workPackage)
            }
            .navigationDestination(item: $spoolToEdit) { spool in
                SpoolDetailView(spool: spool)
            }
            .sheet(item: $spoolToEmail) { spool in
                SpoolMailComposer(
                    spool: spool,
                    project: project,
                    workPackage: workPackage,
                    isPresented: Binding(
                        get: { spoolToEmail != nil },
                        set: { if !$0 { spoolToEmail = nil } }
                    )
                )
            }
            .alert("Cannot Send Email", isPresented: $showingMailError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please configure an email account in Settings to send emails.")
            }
        }
    }

    private func deleteSpool(_ spool: Spool) {
        // Remove from work package's assigned spools
        workPackage.assignedSpools.removeAll { $0.id == spool.id }
        // Delete from model context
        modelContext.delete(spool)
        try? modelContext.save()
    }
}

// MARK: - Mail Composer

struct SpoolMailComposer: UIViewControllerRepresentable {
    let spool: Spool
    let project: Project
    let workPackage: WorkPackage
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator

        // Set subject: Project Name - Package Number - Spool Number
        let subject = "\(project.name) - PKG \(workPackage.packageNumber) - Spool \(spool.name)"
        composer.setSubject(subject)

        // Generate PDF and attach
        if let pdfData = generateSpoolPDF() {
            let filename = "Spool_\(spool.name).pdf"
            composer.addAttachmentData(pdfData, mimeType: "application/pdf", fileName: filename)
        }

        // Optional: Add body text
        let body = """
        Please find attached the spool sheet for:

        Project: \(project.name)
        Job #: \(project.jobNumber)
        Package: \(workPackage.name) (PKG #\(workPackage.packageNumber))
        Spool: \(spool.name)
        Status: \(spool.status)

        """
        composer.setMessageBody(body, isHTML: false)

        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    func generateSpoolPDF() -> Data? {
        // Create a static PDF view with pre-loaded data
        let printView = SpoolPDFView(spool: spool, project: project, workPackage: workPackage)

        // Page size: 8.5 x 11 landscape
        let pageWidth: CGFloat = 11 * 72  // 792 points
        let pageHeight: CGFloat = 8.5 * 72  // 612 points
        let pageSize = CGSize(width: pageWidth, height: pageHeight)

        // Render to PDF
        let renderer = ImageRenderer(content:
            printView
                .frame(width: pageWidth, height: pageHeight)
                .background(Color.white)
        )

        renderer.scale = 2.0  // Higher resolution

        let pdfData = NSMutableData()

        renderer.render { size, renderContext in
            var box = CGRect(origin: .zero, size: pageSize)

            guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
                  let context = CGContext(consumer: consumer, mediaBox: &box, nil) else {
                return
            }

            context.beginPDFPage(nil)
            renderContext(context)
            context.endPDFPage()
            context.closePDF()
        }

        return pdfData as Data
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: SpoolMailComposer

        init(_ parent: SpoolMailComposer) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.isPresented = false
        }
    }
}

// MARK: - Static PDF View for Rendering

/// A static view for PDF rendering that doesn't rely on onAppear
struct SpoolPDFView: View {
    let spool: Spool
    let project: Project
    let workPackage: WorkPackage

    // Page dimensions
    let pageWidth: CGFloat = 11 * 72  // 792 points
    let pageHeight: CGFloat = 8.5 * 72  // 612 points
    let pageMargin: CGFloat = 20
    let rightPanelWidth: CGFloat = 190
    let scale: CGFloat = 2.0

    var contentWidth: CGFloat { pageWidth - (pageMargin * 2) }
    var contentHeight: CGFloat { pageHeight - (pageMargin * 2) }
    var drawingAreaWidth: CGFloat { contentWidth - rightPanelWidth - 10 }
    var drawingAreaHeight: CGFloat { contentHeight }

    var pipePoints: [PipePoint] { spool.pipePoints }

    // Fitting item for BOM
    struct FittingItem {
        let fittingType: FittingType
        let enteringSize: PipeSize?
        let exitingSize: PipeSize?
        let pointIndex: Int
        let isInferred: Bool
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
                items.append(FittingItem(
                    fittingType: point.fittingType,
                    enteringSize: enteringSize,
                    exitingSize: exitingSize,
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
                        pointIndex: index,
                        isInferred: true
                    ))
                }
            }
        }
        return items
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
        } else if turnAngle >= 35 && turnAngle <= 55 {
            return .elbow45
        } else if turnAngle >= 10 {
            return .elbow90
        }
        return .none
    }

    func formatFittingSize(_ item: FittingItem) -> String {
        let entering = item.enteringSize?.shortName ?? "—"
        let exiting = item.exitingSize?.shortName ?? "—"

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

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Left: Drawing area
                drawingCanvas()
                    .frame(width: drawingAreaWidth, height: drawingAreaHeight)

                Spacer()
                    .frame(width: 10)

                // Right: BOM and Metadata
                VStack(spacing: 10) {
                    billOfMaterialsView()
                        .frame(width: rightPanelWidth)
                        .padding(8)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    Spacer()

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
                Rectangle()
                    .stroke(Color.black, lineWidth: 1.5)
                    .padding(pageMargin)
            )
        }
        .frame(width: pageWidth, height: pageHeight)
        .background(Color.white)
    }

    @ViewBuilder
    func drawingCanvas() -> some View {
        let result = calculateCenteredOffset()
        let centerOffset = result.0
        let drawZoom = result.1

        GeometryReader { geo in
            canvasContentView(centerOffset: centerOffset, drawZoom: drawZoom, geo: geo)
        }
        .background(Color.white)
        .clipped()
    }

    @ViewBuilder
    private func canvasContentView(centerOffset: CGSize, drawZoom: CGFloat, geo: GeometryProxy) -> some View {
        ZStack {
            Color.white

            pipeSegmentsCanvasView(drawZoom: drawZoom)
            pointMarkersCanvasView(drawZoom: drawZoom)
        }
        .frame(width: geo.size.width, height: geo.size.height)
        .scaleEffect(drawZoom, anchor: .center)
        .offset(x: centerOffset.width, y: centerOffset.height)
    }

    @ViewBuilder
    private func pipeSegmentsCanvasView(drawZoom: CGFloat) -> some View {
        // Main run segments (skip if next point is a branch)
        ForEach(0..<max(0, pipePoints.count - 1), id: \.self) { i in
            // Don't draw segment if the next point is a branch from another tee
            if pipePoints[i + 1].branchParentId == nil {
                ZStack {
                    PipeSegmentView(
                        segmentIndex: i,
                        start: pipePoints[i].position,
                        end: pipePoints[i + 1].position,
                        scale: scale,
                        zoomScale: drawZoom,
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

                        // Segment number bubble (with offset support)
                        let midPoint = CGPoint(
                            x: (pipePoints[i].position.x + pipePoints[i + 1].position.x) / 2,
                            y: (pipePoints[i].position.y + pipePoints[i + 1].position.y) / 2
                        )

                        // Calculate actual offset position
                        let segmentOffset = pipePoints[i].segmentBubbleOffset
                        let actualOffset = segmentOffset.map { CGSize(width: $0.width / drawZoom, height: $0.height / drawZoom) } ?? .zero
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
                            .frame(width: 24 / drawZoom, height: 24 / drawZoom)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2 / drawZoom)
                            )
                            .overlay(
                                Text(indexToLetter(i))
                                    .font(.system(size: 12 / drawZoom, weight: .bold))
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
                    zoomScale: drawZoom,
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
                let actualOffset = segmentOffset.map { CGSize(width: $0.width / drawZoom, height: $0.height / drawZoom) } ?? .zero
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
                    .frame(width: 24 / drawZoom, height: 24 / drawZoom)
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 2 / drawZoom)
                    )
                    .overlay(
                        Text(indexToLetter(index))
                            .font(.system(size: 12 / drawZoom, weight: .bold))
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
    private func pointMarkersCanvasView(drawZoom: CGFloat) -> some View {
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
                zoomScale: drawZoom,
                bubbleLabelOffset: .constant(pipePoint.bubbleLabelOffset),
                isDraggingAnyLabel: .constant(false),
                onTap: {}
            )
        }
    }

    func calculateCenteredOffset() -> (CGSize, CGFloat) {
        guard !pipePoints.isEmpty else {
            return (.zero, 1.0)
        }

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

        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2
        let bboxWidth = maxX - minX
        let bboxHeight = maxY - minY

        var drawZoom: CGFloat = 1.0
        let targetWidth = drawingAreaWidth * 0.8
        let targetHeight = drawingAreaHeight * 0.8

        if bboxWidth > 0 && bboxHeight > 0 {
            let scaleX = targetWidth / bboxWidth
            let scaleY = targetHeight / bboxHeight
            let fitScale = min(scaleX, scaleY, 1.0)
            if fitScale < 1.0 {
                drawZoom = fitScale
            }
        }

        let offset = CGSize(
            width: drawingAreaWidth / 2 - centerX * drawZoom,
            height: drawingAreaHeight / 2 - centerY * drawZoom
        )

        return (offset, drawZoom)
    }

    @ViewBuilder
    func billOfMaterialsView() -> some View {
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
                VStack(alignment: .leading, spacing: 2) {
                    // Header
                    HStack(spacing: 3) {
                        Text("Tag")
                            .font(.system(size: 7, weight: .bold))
                            .frame(width: 24, alignment: .center)
                        Text("Description")
                            .font(.system(size: 7, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Size")
                            .font(.system(size: 7, weight: .bold))
                            .frame(width: 30, alignment: .center)
                        Text("Length")
                            .font(.system(size: 7, weight: .bold))
                            .frame(width: 42, alignment: .trailing)
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .background(Color.gray.opacity(0.15))

                    Divider()

                    // Rows
                    ForEach(Array(pipePoints.enumerated()), id: \.offset) { index, point in
                        // Point row
                        let fittingItem = fittingItems.first(where: { $0.pointIndex == index })

                        HStack(spacing: 3) {
                            Circle()
                                .fill(pointColor(index: index, point: point))
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Text("\(index + 1)")
                                        .font(.system(size: 5, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .frame(width: 24, alignment: .center)

                            // Fitting description
                            if point.fittingType != .none {
                                Text(point.fittingType.rawValue)
                                    .font(.system(size: 7))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else if let fitting = fittingItem, fitting.isInferred {
                                Text("\(fitting.fittingType.rawValue)*")
                                    .font(.system(size: 7))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.orange)
                            } else {
                                Text("Point")
                                    .font(.system(size: 7))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.secondary)
                            }

                            // Fitting size
                            if let fitting = fittingItem {
                                Text(formatFittingSize(fitting))
                                    .font(.system(size: 7))
                                    .frame(width: 30, alignment: .center)
                            } else {
                                Text("—")
                                    .font(.system(size: 7))
                                    .frame(width: 30, alignment: .center)
                                    .foregroundColor(.secondary)
                            }

                            Text("—")
                                .font(.system(size: 7))
                                .frame(width: 42, alignment: .trailing)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 1)
                        .padding(.horizontal, 4)

                        // Pipe segment row
                        if index < pipePoints.count - 1 {
                            HStack(spacing: 3) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 1)
                                        .frame(width: 12, height: 12)
                                    Text(indexToLetter(index))
                                        .font(.system(size: 5, weight: .bold))
                                        .foregroundColor(.blue)
                                }
                                .frame(width: 24, alignment: .center)

                                Text("Pipe")
                                    .font(.system(size: 7))
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(point.pipeSize == .none ? "—" : point.pipeSize.shortName)
                                    .font(.system(size: 7))
                                    .frame(width: 30, alignment: .center)

                                let length = segmentLength(from: point.position, to: pipePoints[index + 1].position)
                                Text(formatFeetInches(inches: length))
                                    .font(.system(size: 7, weight: .medium))
                                    .frame(width: 42, alignment: .trailing)
                            }
                            .padding(.vertical, 1)
                            .padding(.horizontal, 4)
                            .background(Color.blue.opacity(0.05))

                            Divider()
                        }
                    }

                    // Total
                    if pipePoints.count > 1 {
                        HStack(spacing: 3) {
                            Text("Total")
                                .font(.system(size: 7, weight: .bold))
                                .frame(width: 24, alignment: .leading)
                            Spacer()
                            Text(formatFeetInches(inches: totalPipeLength))
                                .font(.system(size: 7, weight: .bold))
                                .frame(width: 42, alignment: .trailing)
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                        .background(Color.gray.opacity(0.2))
                    }
                }
            }
        }
    }

    @ViewBuilder
    func projectMetadataView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
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

            if let spec = spool.effectivePipeSpecification {
                HStack {
                    Text("Pipe Spec:")
                        .font(.system(size: 8, weight: .semibold))
                    Spacer()
                    Text(spec.abbreviation)
                        .font(.system(size: 8))
                }
            }

            HStack {
                Text("Date:")
                    .font(.system(size: 8, weight: .semibold))
                Spacer()
                Text(spool.modifiedDate, style: .date)
                    .font(.system(size: 8))
            }

            Divider()

            if UserProfile.shared.hasProfile {
                HStack {
                    Text("Author:")
                        .font(.system(size: 8, weight: .semibold))
                    Spacer()
                    Text(UserProfile.shared.displayName)
                        .font(.system(size: 8))
                        .lineLimit(1)
                }

                if !UserProfile.shared.displayPhone.isEmpty {
                    HStack {
                        Text("Phone:")
                            .font(.system(size: 8, weight: .semibold))
                        Spacer()
                        Text(UserProfile.shared.displayPhone)
                            .font(.system(size: 8))
                    }
                }
            }
        }
    }

    func pointColor(index: Int, point: PipePoint) -> Color {
        if index == 0 { return .green }
        if index == pipePoints.count - 1 { return .red }
        if point.fittingType != .none { return .blue }
        return .orange
    }

    func segmentLength(from start: CGPoint, to end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        return sqrt(dx * dx + dy * dy) / scale
    }

    var totalPipeLength: CGFloat {
        var total: CGFloat = 0
        for i in 0..<(pipePoints.count - 1) {
            total += segmentLength(from: pipePoints[i].position, to: pipePoints[i + 1].position)
        }
        return total
    }
}

/// Sheet for moving a spool to a different work package or unassigning it
struct MoveSpoolSheet: View {
    @Bindable var spool: Spool
    @Bindable var project: Project
    let currentPackage: WorkPackage?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDestination: MoveDestination? = nil

    enum MoveDestination: Hashable {
        case unassigned
        case workPackage(UUID)
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Current Location")) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.orange)

                        if let pkg = currentPackage {
                            Text("\(pkg.name) (PKG #\(pkg.packageNumber))")
                        } else {
                            Text("Unassigned")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("Move To")) {
                    // Unassigned option
                    Button {
                        selectedDestination = .unassigned
                    } label: {
                        HStack {
                            Image(systemName: "tray")
                                .foregroundColor(.gray)

                            Text("Unassigned")
                                .foregroundColor(.primary)

                            Spacer()

                            if selectedDestination == .unassigned {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    // Work packages
                    ForEach(project.workPackages) { package in
                        if package.id != currentPackage?.id {
                            Button {
                                selectedDestination = .workPackage(package.id)
                            } label: {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.orange)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(package.name)
                                            .foregroundColor(.primary)

                                        Text("PKG #\(package.packageNumber)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if selectedDestination == .workPackage(package.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move Spool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Move") {
                        moveSpool()
                    }
                    .disabled(selectedDestination == nil)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func moveSpool() {
        // Remove from current location
        if let currentPkg = currentPackage {
            currentPkg.assignedSpools.removeAll { $0.id == spool.id }
        } else {
            project.spools.removeAll { $0.id == spool.id }
        }

        // Move to new location
        switch selectedDestination {
        case .unassigned:
            spool.workPackage = nil
            project.spools.append(spool)

        case .workPackage(let packageId):
            if let targetPackage = project.workPackages.first(where: { $0.id == packageId }) {
                spool.workPackage = targetPackage
                targetPackage.assignedSpools.append(spool)
            }

        case .none:
            break
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    WorkPackageSpoolsListView(
        workPackage: WorkPackage(
            name: "Ground Floor",
            packageNumber: "001",
            status: "In Progress"
        ),
        project: Project(
            name: "Office Building",
            jobNumber: "2026"
        )
    )
    .modelContainer(DataController.shared.container)
}
