//
//  SpoolDetailView.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI
import SwiftData

/// Detailed view for editing a spool's pipe drawing
struct SpoolDetailView: View {
    @Bindable var spool: Spool
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var pipePoints: [PipePoint] = []
    @State private var editingSegment: Int? = nil
    @State private var editValue: String = ""
    @State private var editMeasurementType: String? = nil
    @State private var showingKeypad: Bool = false
    @State private var breakModeEnabled: Bool = false
    @State private var branchModeEnabled: Bool = false
    @State private var oletModeEnabled: Bool = false
    @State private var selectedOletSegment: Int? = nil
    @State private var selectedOletId: UUID? = nil
    @State private var showingOletPicker: Bool = false
    @State private var selectedPointIndex: Int? = nil
    @State private var showingFittingPicker: Bool = false
    @State private var selectedSegmentForSize: Int? = nil
    @State private var showingPipeSizePicker: Bool = false
    @State private var showingBOM: Bool = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var lastPanOffset: CGSize = .zero
    @State private var isDraggingLabel: Bool = false
    @State private var showingClearConfirmation: Bool = false

    let scale: CGFloat = 2.0
    let minZoom: CGFloat = 0.1
    let maxZoom: CGFloat = 8.0
    let allowedAngles: [CGFloat] = [30, 90, 150, 210, 270, 330]

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad layout with sidebar
                iPadLayout()
            } else {
                // iPhone layout (original)
                iPhoneLayout()
            }
        }
        .navigationTitle(spool.name)
        .navigationBarTitleDisplayMode(horizontalSizeClass == .regular ? .inline : .large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                makePreviewButton()
            }
        }
        .onAppear {
            loadSpool()
        }
        .onDisappear {
            saveSpool()
        }
        .sheet(isPresented: $showingKeypad) {
            MeasurementKeypad(
                value: $editValue,
                measurementType: $editMeasurementType,
                segmentNumber: (editingSegment ?? 0) + 1,
                onCancel: {
                    showingKeypad = false
                    editingSegment = nil
                },
                onSubmit: {
                    applyEdit()
                    showingKeypad = false
                }
            )
            .presentationDetents([.height(500)])
        }
        .sheet(isPresented: $showingFittingPicker) {
            FittingTypePicker(
                selectedType: selectedPointIndex != nil ? pipePoints[selectedPointIndex!].fittingType : .none,
                selectedOrientation: selectedPointIndex != nil ? pipePoints[selectedPointIndex!].fittingOrientation : nil,
                pointNumber: (selectedPointIndex ?? 0) + 1,
                isEndPoint: selectedPointIndex == 0 || selectedPointIndex == pipePoints.count - 1,
                onSelect: { fittingType, orientation in
                    if let index = selectedPointIndex {
                        pipePoints[index].fittingType = fittingType
                        pipePoints[index].fittingOrientation = orientation
                        saveSpool()
                    }
                    showingFittingPicker = false
                    selectedPointIndex = nil
                },
                onCancel: {
                    showingFittingPicker = false
                    selectedPointIndex = nil
                }
            )
            .presentationDetents([.large, .medium])
        }
        .sheet(isPresented: $showingPipeSizePicker) {
            PipeSizePicker(
                selectedSize: selectedSegmentForSize != nil ? pipePoints[selectedSegmentForSize!].pipeSize : .none,
                segmentNumber: (selectedSegmentForSize ?? 0) + 1,
                onSelect: { pipeSize in
                    if let index = selectedSegmentForSize {
                        pipePoints[index].pipeSize = pipeSize
                        saveSpool()
                    }
                    showingPipeSizePicker = false
                    selectedSegmentForSize = nil
                },
                onCancel: {
                    showingPipeSizePicker = false
                    selectedSegmentForSize = nil
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingOletPicker) {
            if let segmentIndex = selectedOletSegment,
               let oletId = selectedOletId,
               segmentIndex < pipePoints.count {

                let oletIndex = pipePoints[segmentIndex].olets.firstIndex(where: { $0.id == oletId })
                let olet = oletIndex != nil ? pipePoints[segmentIndex].olets[oletIndex!] : nil

                OletPicker(
                    selectedType: olet?.type ?? .weldolet,
                    selectedOrientation: olet?.orientation ?? 90,
                    selectedSize: olet?.size ?? pipePoints[segmentIndex].pipeSize,
                    onSelect: { type, orientation, size in
                        if let oIndex = pipePoints[segmentIndex].olets.firstIndex(where: { $0.id == oletId }) {
                            pipePoints[segmentIndex].olets[oIndex].type = type
                            pipePoints[segmentIndex].olets[oIndex].orientation = orientation
                            pipePoints[segmentIndex].olets[oIndex].size = size
                            saveSpool()
                        }
                        showingOletPicker = false
                        selectedOletSegment = nil
                        selectedOletId = nil
                    },
                    onDelete: {
                        if let oIndex = pipePoints[segmentIndex].olets.firstIndex(where: { $0.id == oletId }) {
                            pipePoints[segmentIndex].olets.remove(at: oIndex)
                            saveSpool()
                        }
                        showingOletPicker = false
                        selectedOletSegment = nil
                        selectedOletId = nil
                    },
                    onCancel: {
                        showingOletPicker = false
                        selectedOletSegment = nil
                        selectedOletId = nil
                    }
                )
                .presentationDetents([.medium, .large])
            } else {
                VStack(spacing: 20) {
                    Text("Debug Info")
                        .font(.headline)
                    Text("Segment: \(selectedOletSegment?.description ?? "nil")")
                    Text("Olet ID: \(selectedOletId?.uuidString ?? "nil")")
                    Text("Points count: \(pipePoints.count)")
                    Button("Close") {
                        showingOletPicker = false
                        selectedOletSegment = nil
                        selectedOletId = nil
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingBOM) {
            BillOfMaterialsView(
                pipePoints: pipePoints,
                scale: scale,
                onDismiss: { showingBOM = false }
            )
            .presentationDetents([.large])
        }
        .alert("Clear All Points?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                pipePoints.removeAll()
                saveSpool()
            }
        } message: {
            Text("This will delete all pipe points and cannot be undone.")
        }
    }

    // MARK: - Layout Variants

    @ViewBuilder
    private func iPadLayout() -> some View {
        HStack(spacing: 0) {
            // Tool sidebar
            toolSidebar()
                .frame(width: PipeFabARTheme.sidebarWidth)
                .background(Color(.systemGray6))

            Divider()

            // Drawing canvas
            drawingCanvasView
        }
    }

    @ViewBuilder
    private func iPhoneLayout() -> some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Text(spool.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                // Clear button
                Button("Clear") {
                    showingClearConfirmation = true
                }

                // BOM button
                Button(action: { showingBOM = true }) {
                    Image(systemName: "list.clipboard")
                }
                .disabled(pipePoints.count < 2)
                .padding(.leading, 8)
            }
            .padding()
            .background(Color(.systemGray6))

            // Drawing canvas
            drawingCanvasView

            // Tool bar
            HStack(spacing: 12) {
                // Break mode toggle
                Button(action: {
                    breakModeEnabled.toggle()
                    if breakModeEnabled {
                        branchModeEnabled = false
                        oletModeEnabled = false
                    }
                }) {
                    Image(systemName: "scissors")
                        .foregroundColor(breakModeEnabled ? .white : .primary)
                        .font(.system(size: 16))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(breakModeEnabled ? Color.orange : Color.gray.opacity(0.2))
                .cornerRadius(6)

                // Branch mode toggle
                Button(action: {
                    branchModeEnabled.toggle()
                    if branchModeEnabled {
                        breakModeEnabled = false
                        oletModeEnabled = false
                    }
                }) {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundColor(branchModeEnabled ? .white : .primary)
                        .font(.system(size: 16))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(branchModeEnabled ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(6)

                // O'let mode toggle
                Button(action: {
                    oletModeEnabled.toggle()
                    if oletModeEnabled {
                        breakModeEnabled = false
                        branchModeEnabled = false
                    }
                }) {
                    Image(systemName: "circle.dotted")
                        .foregroundColor(oletModeEnabled ? .white : .primary)
                        .font(.system(size: 16))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(oletModeEnabled ? Color.purple : Color.gray.opacity(0.2))
                .cornerRadius(6)

                Divider()
                    .frame(height: 24)

                // Zoom controls
                HStack(spacing: 6) {
                    Button(action: zoomOut) {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.system(size: 14))
                    }
                    .disabled(zoomScale <= minZoom)

                    Text("\(Int(zoomScale * 100))%")
                        .font(.caption2)
                        .frame(width: 40)

                    Button(action: zoomIn) {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.system(size: 14))
                    }
                    .disabled(zoomScale >= maxZoom)

                    Button(action: resetZoom) {
                        Image(systemName: "1.magnifyingglass")
                            .font(.system(size: 14))
                    }

                    Button(action: recenterSpool) {
                        Image(systemName: "scope")
                            .font(.system(size: 14))
                    }
                    .disabled(pipePoints.count < 2)
                }

                Divider()
                    .frame(height: 24)

                // Undo button
                Button(action: undo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16))
                }
                .disabled(pipePoints.count < 2)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray5))

            // Bottom info bar
            HStack {
                if breakModeEnabled {
                    Text("Break mode: Tap on a pipe to split it")
                        .font(.caption2)
                        .foregroundColor(.orange)
                } else {
                    Text("Tap to add points • Tap measurement to edit • Tap point for fitting")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if pipePoints.count >= 2 {
                    Text("Total: \(formattedTotal)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
        }
    }

    @ViewBuilder
    private func toolSidebar() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with spool info
            VStack(alignment: .leading, spacing: 8) {
                Text(spool.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(2)

                if pipePoints.count >= 2 {
                    HStack {
                        Text("Total:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(formattedTotal)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Scrollable tools
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Mode section
                    toolSection(title: "Mode") {
                        Toggle(isOn: $breakModeEnabled) {
                            Label("Break Mode", systemImage: "scissors")
                        }
                        .tint(.orange)
                        .onChange(of: breakModeEnabled) {
                            if breakModeEnabled {
                                branchModeEnabled = false
                                oletModeEnabled = false
                            }
                        }

                        if breakModeEnabled {
                            Text("Tap on a pipe to split it")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }

                        Toggle(isOn: $branchModeEnabled) {
                            Label("Branch Mode", systemImage: "arrow.triangle.branch")
                        }
                        .tint(.blue)
                        .onChange(of: branchModeEnabled) {
                            if branchModeEnabled {
                                breakModeEnabled = false
                                oletModeEnabled = false
                            }
                        }

                        if branchModeEnabled {
                            Text("Tap on a tee to add a branch")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }

                        Toggle(isOn: $oletModeEnabled) {
                            Label("O'let Mode", systemImage: "circle.dotted")
                        }
                        .tint(.purple)
                        .onChange(of: oletModeEnabled) {
                            if oletModeEnabled {
                                breakModeEnabled = false
                                branchModeEnabled = false
                            }
                        }

                        if oletModeEnabled {
                            Text("Tap on a pipe segment to add an o'let")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }

                    Divider()

                    // View section
                    toolSection(title: "View") {
                        HStack {
                            Button(action: zoomOut) {
                                Label("Zoom Out", systemImage: "minus.magnifyingglass")
                                    .labelStyle(.iconOnly)
                            }
                            .disabled(zoomScale <= minZoom)
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.bordered)

                            Text("\(Int(zoomScale * 100))%")
                                .font(.caption)
                                .frame(width: 60)

                            Button(action: zoomIn) {
                                Label("Zoom In", systemImage: "plus.magnifyingglass")
                                    .labelStyle(.iconOnly)
                            }
                            .disabled(zoomScale >= maxZoom)
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.bordered)
                        }

                        Button(action: resetZoom) {
                            Label("Reset Zoom", systemImage: "1.magnifyingglass")
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)

                        Button(action: recenterSpool) {
                            Label("Center Canvas", systemImage: "scope")
                        }
                        .disabled(pipePoints.count < 2)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                    }

                    Divider()

                    // Actions section
                    toolSection(title: "Actions") {
                        Button(action: undo) {
                            Label("Undo", systemImage: "arrow.uturn.backward")
                        }
                        .disabled(pipePoints.count < 2)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)

                        Button(action: { showingBOM = true }) {
                            Label("Bill of Materials", systemImage: "list.clipboard")
                        }
                        .disabled(pipePoints.count < 2)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)

                        Button(action: { showingClearConfirmation = true }) {
                            Label("Clear All", systemImage: "trash")
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }

                    Divider()

                    // Instructions
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Instructions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text("• Tap to add points\n• Tap measurement to edit\n• Tap point for fitting")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private func toolSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
        }
    }

    // MARK: - View Components

    private var drawingCanvasView: some View {
        GeometryReader { geo in
            canvasContent(geo: geo)
        }
        .background(Color.white)
        .clipped()
    }

    @ViewBuilder
    private func canvasContent(geo: GeometryProxy) -> some View {
        ZStack {
            // Background grid (isometric)
            IsometricGridView(allowedAngles: allowedAngles)

            pipeSegmentsView
            oletMarkersView
            pointMarkersView
            logoView
        }
        .scaleEffect(zoomScale)
        .offset(panOffset)
        .contentShape(Rectangle())
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    let oldZoom = zoomScale
                    let newScale = min(max(lastZoomScale * value, minZoom), maxZoom)

                    // Adjust pan offset to keep screen center fixed
                    let scaleFactor = newScale / oldZoom
                    panOffset = CGSize(
                        width: panOffset.width * scaleFactor,
                        height: panOffset.height * scaleFactor
                    )

                    zoomScale = newScale
                }
                .onEnded { _ in
                    lastZoomScale = zoomScale
                    lastPanOffset = panOffset
                    saveSpool()
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    guard !isDraggingLabel else { return }
                    panOffset = CGSize(
                        width: lastPanOffset.width + value.translation.width,
                        height: lastPanOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    guard !isDraggingLabel else { return }
                    lastPanOffset = panOffset
                    saveSpool()
                }
        )
        .onTapGesture { location in
            guard !breakModeEnabled else { return }
            let adjustedLocation = CGPoint(
                x: (location.x - panOffset.width - geo.size.width / 2) / zoomScale + geo.size.width / 2,
                y: (location.y - panOffset.height - geo.size.height / 2) / zoomScale + geo.size.height / 2
            )
            addPoint(at: adjustedLocation)
        }
    }

    @ViewBuilder
    private var pipeSegmentsView: some View {
        // Main run segments (skip if next point is a branch)
        ForEach(0..<max(0, pipePoints.count - 1), id: \.self) { i in
            // Don't draw segment if the next point is a branch from another tee
            if pipePoints[i + 1].branchParentId == nil {
                let midpoint = CGPoint(
                    x: (pipePoints[i].position.x + pipePoints[i + 1].position.x) / 2,
                    y: (pipePoints[i].position.y + pipePoints[i + 1].position.y) / 2
                )

                PipeSegmentView(
                    segmentIndex: i,
                    start: pipePoints[i].position,
                    end: pipePoints[i + 1].position,
                    scale: scale,
                    zoomScale: zoomScale,
                    measurementType: pipePoints[i].measurementType,
                    pipeSize: pipePoints[i].pipeSize,
                    dimensionLabelOffset: $pipePoints[i].dimensionLabelOffset,
                    sizeLabelOffset: $pipePoints[i].sizeLabelOffset,
                    isDraggingAnyLabel: $isDraggingLabel,
                    breakModeEnabled: breakModeEnabled,
                    oletModeEnabled: oletModeEnabled,
                    onTapMeasurement: { index in
                        startEditing(segment: index)
                    },
                    onTapPipeSize: { index in
                        selectedSegmentForSize = index
                        showingPipeSizePicker = true
                    },
                    onTapLine: { index, location in
                        if breakModeEnabled {
                            breakSegment(at: index, tapLocation: location)
                        } else if oletModeEnabled {
                            addOletToSegment(at: index, tapLocation: location)
                        }
                    }
                )

                SegmentBubbleView(
                    segmentIndex: i,
                    midpoint: midpoint,
                    zoomScale: zoomScale,
                    segmentBubbleOffset: $pipePoints[i].segmentBubbleOffset,
                    isDraggingAnyLabel: $isDraggingLabel
                )
            }
        }

        // Branch segments (from parent tees to branch points)
        ForEach(Array(pipePoints.enumerated()), id: \.offset) { index, pipePoint in
            if let parentId = pipePoint.branchParentId,
               let parentIndex = pipePoints.firstIndex(where: { $0.id == parentId }) {
                let midpoint = CGPoint(
                    x: (pipePoints[parentIndex].position.x + pipePoint.position.x) / 2,
                    y: (pipePoints[parentIndex].position.y + pipePoint.position.y) / 2
                )

                PipeSegmentView(
                    segmentIndex: index,
                    start: pipePoints[parentIndex].position,
                    end: pipePoint.position,
                    scale: scale,
                    zoomScale: zoomScale,
                    measurementType: pipePoint.measurementType,
                    pipeSize: pipePoint.pipeSize,
                    dimensionLabelOffset: $pipePoints[index].branchDimensionLabelOffset,
                    sizeLabelOffset: $pipePoints[index].branchSizeLabelOffset,
                    isDraggingAnyLabel: $isDraggingLabel,
                    breakModeEnabled: breakModeEnabled,
                    oletModeEnabled: oletModeEnabled,
                    onTapMeasurement: { segmentIndex in
                        startEditing(segment: segmentIndex)
                    },
                    onTapPipeSize: { segmentIndex in
                        selectedSegmentForSize = segmentIndex
                        showingPipeSizePicker = true
                    },
                    onTapLine: { segmentIndex, location in
                        if breakModeEnabled {
                            breakSegment(at: segmentIndex, tapLocation: location)
                        } else if oletModeEnabled {
                            addOletToSegment(at: segmentIndex, tapLocation: location)
                        }
                    }
                )

                SegmentBubbleView(
                    segmentIndex: index,
                    midpoint: midpoint,
                    zoomScale: zoomScale,
                    segmentBubbleOffset: $pipePoints[index].branchSegmentBubbleOffset,
                    isDraggingAnyLabel: $isDraggingLabel
                )
            }
        }
    }

    @ViewBuilder
    private var oletMarkersView: some View {
        // O'lets on main run segments
        ForEach(0..<max(0, pipePoints.count - 1), id: \.self) { i in
            if pipePoints[i + 1].branchParentId == nil {
                ForEach(Array(pipePoints[i].olets.indices), id: \.self) { oletIndex in
                    OletMarkerView(
                        olet: pipePoints[i].olets[oletIndex],
                        segmentStart: pipePoints[i].position,
                        segmentEnd: pipePoints[i + 1].position,
                        zoomScale: zoomScale,
                        scale: scale,
                        dimensionLabelOffset: $pipePoints[i].olets[oletIndex].dimensionLabelOffset,
                        isDraggingAnyLabel: $isDraggingLabel,
                        onTap: {
                            selectedOletSegment = i
                            selectedOletId = pipePoints[i].olets[oletIndex].id
                            showingOletPicker = true
                        },
                        onTapDimension: {
                            selectedOletSegment = i
                            selectedOletId = pipePoints[i].olets[oletIndex].id
                            showingOletPicker = true
                        }
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
                        zoomScale: zoomScale,
                        scale: scale,
                        dimensionLabelOffset: $pipePoints[parentIndex].olets[oletIndex].dimensionLabelOffset,
                        isDraggingAnyLabel: $isDraggingLabel,
                        onTap: {
                            selectedOletSegment = parentIndex
                            selectedOletId = pipePoints[parentIndex].olets[oletIndex].id
                            showingOletPicker = true
                        },
                        onTapDimension: {
                            selectedOletSegment = parentIndex
                            selectedOletId = pipePoints[parentIndex].olets[oletIndex].id
                            showingOletPicker = true
                        }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var pointMarkersView: some View {
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
                zoomScale: zoomScale,
                bubbleLabelOffset: $pipePoints[index].bubbleLabelOffset,
                isDraggingAnyLabel: $isDraggingLabel,
                onTap: {
                    if branchModeEnabled {
                        createBranchFromTee(at: index)
                    } else {
                        selectedPointIndex = index
                        showingFittingPicker = true
                    }
                }
            )
        }
    }

    private var logoView: some View {
        VStack {
            Spacer()
            HStack {
                BrandingView(size: 32)
                    .scaleEffect(1.0 / zoomScale)
                Spacer()
            }
        }
        .padding(8)
        .allowsHitTesting(false)
    }

    // MARK: - Data Management

    func loadSpool() {
        pipePoints = spool.pipePoints
        zoomScale = CGFloat(spool.zoomScale)
        lastZoomScale = zoomScale
        panOffset = spool.panOffset
        lastPanOffset = panOffset
    }

    func saveSpool() {
        spool.pipePoints = pipePoints
        spool.zoomScale = Double(zoomScale)
        spool.panOffset = panOffset
        spool.modifiedDate = Date()

        // Generate thumbnail if there are points
        if !pipePoints.isEmpty {
            // TODO: Generate thumbnail image
        }

        try? modelContext.save()
    }

    // MARK: - Drawing Functions

    func undo() {
        if pipePoints.count > 1 {
            pipePoints.removeLast()
            saveSpool()
        }
    }

    func zoomIn() {
        let oldZoom = zoomScale
        let newZoom = min(zoomScale * 1.5, maxZoom)

        withAnimation(.easeInOut(duration: 0.2)) {
            // Adjust pan offset to keep screen center fixed
            let scaleFactor = newZoom / oldZoom
            panOffset = CGSize(
                width: panOffset.width * scaleFactor,
                height: panOffset.height * scaleFactor
            )
            lastPanOffset = panOffset

            zoomScale = newZoom
            lastZoomScale = newZoom
        }
    }

    func zoomOut() {
        let oldZoom = zoomScale
        let newZoom = max(zoomScale / 1.5, minZoom)

        withAnimation(.easeInOut(duration: 0.2)) {
            // Adjust pan offset to keep screen center fixed
            let scaleFactor = newZoom / oldZoom
            panOffset = CGSize(
                width: panOffset.width * scaleFactor,
                height: panOffset.height * scaleFactor
            )
            lastPanOffset = panOffset

            zoomScale = newZoom
            lastZoomScale = newZoom
        }
    }

    func resetZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = 1.0
            lastZoomScale = 1.0
            panOffset = .zero
            lastPanOffset = .zero
        }
    }

    func recenterSpool() {
        guard pipePoints.count >= 2 else {
            resetZoom()
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

        withAnimation(.easeInOut(duration: 0.3)) {
            // Reset zoom to 1.0 and center on the bounding box
            zoomScale = 1.0
            lastZoomScale = 1.0
            // Pan offset to center the bounding box center at screen center
            panOffset = CGSize(width: -centerX, height: -centerY)
            lastPanOffset = panOffset
        }
        saveSpool()
    }

    func startEditing(segment: Int) {
        guard segment < pipePoints.count - 1 else { return }

        // Calculate current segment length and pre-populate
        let start = pipePoints[segment].position
        let end = pipePoints[segment + 1].position
        let dx = end.x - start.x
        let dy = end.y - start.y
        let currentDistance = sqrt(dx * dx + dy * dy)
        let currentLengthInches = currentDistance / scale

        editValue = formatFeetInches(inches: currentLengthInches)
        editMeasurementType = pipePoints[segment].measurementType
        editingSegment = segment
        showingKeypad = true
    }

    func applyEdit() {
        guard let segment = editingSegment,
              segment < pipePoints.count - 1 else {
            editingSegment = nil
            return
        }

        // Check if we have a valid new measurement
        if let newLengthInches = parseMeasurement(editValue), newLengthInches > 0 {
            // Update geometry and measurement type
            let start = pipePoints[segment].position
            let end = pipePoints[segment + 1].position
            let dx = end.x - start.x
            let dy = end.y - start.y
            let currentDistance = sqrt(dx * dx + dy * dy)

            guard currentDistance > 0 else {
                editingSegment = nil
                return
            }

            let dirX = dx / currentDistance
            let dirY = dy / currentDistance
            let newDistance = CGFloat(newLengthInches) * scale
            let newEnd = CGPoint(
                x: start.x + dirX * newDistance,
                y: start.y + dirY * newDistance
            )

            let shiftX = newEnd.x - end.x
            let shiftY = newEnd.y - end.y

            pipePoints[segment + 1].position = newEnd
            pipePoints[segment].measurementType = editMeasurementType

            for i in (segment + 2)..<pipePoints.count {
                pipePoints[i].position = CGPoint(
                    x: pipePoints[i].position.x + shiftX,
                    y: pipePoints[i].position.y + shiftY
                )
            }
        } else {
            // No valid measurement, but still save measurement type if changed
            pipePoints[segment].measurementType = editMeasurementType
        }

        editingSegment = nil
        saveSpool()
    }

    func breakSegment(at segmentIndex: Int, tapLocation: CGPoint) {
        guard segmentIndex < pipePoints.count - 1 else { return }

        let start = pipePoints[segmentIndex].position
        let end = pipePoints[segmentIndex + 1].position
        let breakPoint = closestPointOnSegment(from: start, to: end, point: tapLocation)

        let newPipePoint = PipePoint(position: breakPoint, fittingType: .none)
        pipePoints.insert(newPipePoint, at: segmentIndex + 1)

        breakModeEnabled = false
        selectedPointIndex = segmentIndex + 1
        showingFittingPicker = true
        saveSpool()
    }

    func closestPointOnSegment(from start: CGPoint, to end: CGPoint, point: CGPoint) -> CGPoint {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy

        if lengthSquared == 0 {
            return start
        }

        var t = ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared
        t = max(0, min(1, t))

        return CGPoint(
            x: start.x + t * dx,
            y: start.y + t * dy
        )
    }

    func parseMeasurement(_ input: String) -> Double? {
        var totalInches: Double = 0
        var remaining = input.trimmingCharacters(in: .whitespaces)

        if remaining.hasSuffix("\"") {
            remaining = String(remaining.dropLast())
        }

        if let feetIndex = remaining.firstIndex(of: "'") {
            let feetStr = String(remaining[..<feetIndex])
            if let feet = Double(feetStr) {
                totalInches += feet * 12
            }
            remaining = String(remaining[remaining.index(after: feetIndex)...])
        }

        if remaining.isEmpty {
            return totalInches > 0 ? totalInches : nil
        }

        if let hyphenIndex = remaining.firstIndex(of: "-") {
            let wholeStr = String(remaining[..<hyphenIndex])
            let fractionStr = String(remaining[remaining.index(after: hyphenIndex)...])

            if let whole = Double(wholeStr) {
                totalInches += whole
            }

            if let fraction = parseFraction(fractionStr) {
                totalInches += fraction
            }
        } else if remaining.contains("/") {
            if let fraction = parseFraction(remaining) {
                totalInches += fraction
            }
        } else {
            if let inches = Double(remaining) {
                totalInches += inches
            }
        }

        return totalInches > 0 ? totalInches : nil
    }

    func parseFraction(_ input: String) -> Double? {
        let parts = input.split(separator: "/")
        guard parts.count == 2,
              let numerator = Double(parts[0]),
              let denominator = Double(parts[1]),
              denominator != 0 else {
            return nil
        }
        return numerator / denominator
    }

    func addPoint(at location: CGPoint) {
        if pipePoints.isEmpty {
            pipePoints.append(PipePoint(position: location))
        } else {
            let lastPoint = pipePoints.last!.position
            let snappedPoint = snapToAngle(from: lastPoint, toward: location)
            pipePoints.append(PipePoint(position: snappedPoint))
        }
        saveSpool()
    }

    func createBranchFromTee(at index: Int) {
        guard index < pipePoints.count else { return }
        let teePoint = pipePoints[index]

        // Check if this is a tee fitting
        guard teePoint.fittingType == .tee else {
            return
        }

        // Check if tee has an orientation set
        guard let orientation = teePoint.fittingOrientation else {
            return
        }

        // Check if this tee already has a branch
        let existingBranch = pipePoints.first { $0.branchParentId == teePoint.id }
        if existingBranch != nil {
            return
        }

        // Create a new branch point
        let branchLength: CGFloat = 24.0 * scale // 24 inches
        let angleRad = orientation * .pi / 180
        let branchX = teePoint.position.x + branchLength * cos(angleRad)
        let branchY = teePoint.position.y - branchLength * sin(angleRad)
        let branchPosition = CGPoint(x: branchX, y: branchY)

        var newBranchPoint = PipePoint(position: branchPosition)
        newBranchPoint.branchParentId = teePoint.id
        newBranchPoint.pipeSize = teePoint.pipeSize

        // Append the branch point at the end to avoid breaking the main run
        pipePoints.append(newBranchPoint)

        // Disable branch mode after creating the branch
        branchModeEnabled = false

        // Save the changes
        saveSpool()
    }

    func addOletToSegment(at segmentIndex: Int, tapLocation: CGPoint) {
        print("🔵 addOletToSegment called: segment=\(segmentIndex), location=\(tapLocation)")
        guard segmentIndex < pipePoints.count - 1 else {
            print("🔴 Guard failed: segmentIndex >= pipePoints.count - 1")
            return
        }

        let startPoint = pipePoints[segmentIndex].position
        let endPoint = pipePoints[segmentIndex + 1].position

        // Calculate position along segment (0.0 to 1.0)
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let segmentLength = sqrt(dx * dx + dy * dy)

        guard segmentLength > 0 else { return }

        // Project tap location onto segment to find closest point
        let tapDx = tapLocation.x - startPoint.x
        let tapDy = tapLocation.y - startPoint.y
        let dotProduct = (tapDx * dx + tapDy * dy)
        var position = dotProduct / (segmentLength * segmentLength)

        // Clamp position to segment bounds (0.1 to 0.9 to avoid endpoints)
        position = max(0.1, min(0.9, position))

        // Create new o'let with default settings
        let newOlet = Olet(
            position: position,
            orientation: 90,  // Default upward
            size: pipePoints[segmentIndex].pipeSize  // Match pipe size by default
        )

        // Add o'let to the segment
        pipePoints[segmentIndex].olets.append(newOlet)

        // Show picker to configure the o'let
        selectedOletSegment = segmentIndex
        selectedOletId = newOlet.id
        print("🟢 O'let added: segment=\(segmentIndex), id=\(newOlet.id), showing picker")
        showingOletPicker = true
        print("🟢 showingOletPicker = \(showingOletPicker)")
        saveSpool()
    }

    func snapToAngle(from start: CGPoint, toward target: CGPoint) -> CGPoint {
        let dx = target.x - start.x
        let dy = target.y - start.y
        let distance = sqrt(dx * dx + dy * dy)

        var currentAngle = atan2(-dy, dx) * 180 / .pi
        if currentAngle < 0 { currentAngle += 360 }

        var nearestAngle = allowedAngles[0]
        var smallestDiff = angleDifference(currentAngle, allowedAngles[0])

        for angle in allowedAngles {
            let diff = angleDifference(currentAngle, angle)
            if diff < smallestDiff {
                smallestDiff = diff
                nearestAngle = angle
            }
        }

        let snappedRad = nearestAngle * .pi / 180
        let newX = start.x + distance * cos(snappedRad)
        let newY = start.y - distance * sin(snappedRad)

        return CGPoint(x: newX, y: newY)
    }

    func angleDifference(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        var diff = abs(a - b)
        if diff > 180 { diff = 360 - diff }
        return diff
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

    var formattedTotal: String {
        var total: CGFloat = 0
        for i in 0..<(pipePoints.count - 1) {
            let dx = pipePoints[i + 1].position.x - pipePoints[i].position.x
            let dy = pipePoints[i + 1].position.y - pipePoints[i].position.y
            total += sqrt(dx * dx + dy * dy)
        }
        let inches = total / scale
        return formatFeetInches(inches: inches)
    }

    private func makePreviewButton() -> some View {
        Group {
            if let project = spool.project, let workPackage = spool.workPackage {
                if pipePoints.count >= 2 {
                    NavigationLink(destination: SpoolPrintableView(spool: spool, project: project, workPackage: workPackage)) {
                        Label("Preview", systemImage: "doc.richtext")
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SpoolDetailView(
            spool: Spool(
                name: "2026-001-001",
                systemType: SystemType.hotWater.rawValue,
                status: "Draft"
            )
        )
    }
    .modelContainer(DataController.shared.container)
}
