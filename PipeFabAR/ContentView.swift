import SwiftUI

// Note: FittingType, PipeSize, and PipePoint have been moved to separate Model files

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var pipePoints: [PipePoint] = []
    @State private var editingSegment: Int? = nil
    @State private var editValue: String = ""
    @State private var editMeasurementType: String? = nil
    @State private var showingKeypad: Bool = false

    // Break mode
    @State private var breakModeEnabled: Bool = false

    // Branch mode
    @State private var branchModeEnabled: Bool = false

    // O'let mode
    @State private var oletModeEnabled: Bool = false
    @State private var selectedOletSegment: Int? = nil  // Segment index
    @State private var selectedOletId: UUID? = nil  // O'let ID for editing
    @State private var showingOletPicker: Bool = false

    // Fitting selection
    @State private var selectedPointIndex: Int? = nil
    @State private var showingFittingPicker: Bool = false

    // Pipe size selection
    @State private var selectedSegmentForSize: Int? = nil
    @State private var showingPipeSizePicker: Bool = false

    // Bill of Materials
    @State private var showingBOM: Bool = false

    // Zoom and pan state
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var lastPanOffset: CGSize = .zero

    // Track when labels are being dragged to disable panning
    @State private var isDraggingLabel: Bool = false

    // Scale: points per inch (adjustable)
    // At 2 pts/inch, 20' (240") = 480 points, fits well on screen
    let scale: CGFloat = 2.0
    let minZoom: CGFloat = 0.1
    let maxZoom: CGFloat = 8.0

    // Allowed angles in degrees (isometric orientations)
    // NW=30°, Up=90°, NE=150°, SE=210°, Down=270°, SW=330°
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
            if let segmentIndex = selectedOletSegment, let oletId = selectedOletId {
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
                        }
                        showingOletPicker = false
                        selectedOletSegment = nil
                        selectedOletId = nil
                    },
                    onDelete: {
                        if let oIndex = pipePoints[segmentIndex].olets.firstIndex(where: { $0.id == oletId }) {
                            pipePoints[segmentIndex].olets.remove(at: oIndex)
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
                Text("Pipe Drawing")
                    .font(.headline)

                Spacer()

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
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(breakModeEnabled ? Color.orange : Color.clear)
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
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(branchModeEnabled ? Color.blue : Color.clear)
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
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(oletModeEnabled ? Color.purple : Color.clear)
                .cornerRadius(6)

                // Zoom controls
                HStack(spacing: 4) {
                    Button(action: zoomOut) {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .disabled(zoomScale <= minZoom)

                    Text("\(Int(zoomScale * 100))%")
                        .font(.caption)
                        .frame(width: 45)

                    Button(action: zoomIn) {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .disabled(zoomScale >= maxZoom)

                    Button(action: resetZoom) {
                        Image(systemName: "1.magnifyingglass")
                    }
                }

                // Undo button
                Button(action: undo) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(pipePoints.count < 2)
                .padding(.leading, 8)

                // Clear button
                Button("Clear") {
                    pipePoints.removeAll()
                }
                .padding(.leading, 8)

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

            // Bottom info
            HStack {
                if breakModeEnabled {
                    Text("Break mode: Tap on a pipe to split it")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Tap to add points • Tap measurement to edit • Tap point for fitting")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if pipePoints.count >= 2 {
                    Text("Total: \(formattedTotal)")
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(Color(.systemGray6))
        }
    }

    @ViewBuilder
    private func toolSidebar() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Pipe Drawing")
                    .font(.title3)
                    .fontWeight(.bold)

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

                        Button(action: { pipePoints.removeAll() }) {
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

    private var drawingCanvasView: some View {
        GeometryReader { geo in
            ZStack {
                // Background grid (isometric)
                IsometricGridView(allowedAngles: allowedAngles)

                // Pipes between consecutive points (skip if next point is a branch)
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

                // O'let markers
                oletMarkersView

                // Points
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
            .scaleEffect(zoomScale)
            .offset(panOffset)
            .contentShape(Rectangle())
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        let newScale = lastZoomScale * value
                        zoomScale = min(max(newScale, minZoom), maxZoom)
                    }
                    .onEnded { _ in
                        lastZoomScale = zoomScale
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        // Don't pan if a label is being dragged
                        guard !isDraggingLabel else { return }
                        panOffset = CGSize(
                            width: lastPanOffset.width + value.translation.width,
                            height: lastPanOffset.height + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        guard !isDraggingLabel else { return }
                        lastPanOffset = panOffset
                    }
            )
            .onTapGesture { location in
                guard !breakModeEnabled else { return }
                // Convert tap location to canvas coordinates accounting for zoom and pan
                let adjustedLocation = CGPoint(
                    x: (location.x - panOffset.width - geo.size.width / 2) / zoomScale + geo.size.width / 2,
                    y: (location.y - panOffset.height - geo.size.height / 2) / zoomScale + geo.size.height / 2
                )
                addPoint(at: adjustedLocation)
            }
        }
        .background(Color.white)
        .clipped()
    }

    // MARK: - Helper Functions

    func undo() {
        if pipePoints.count > 1 {
            pipePoints.removeLast()
        }
    }

    func zoomIn() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = min(zoomScale * 1.5, maxZoom)
            lastZoomScale = zoomScale
        }
    }

    func zoomOut() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = max(zoomScale / 1.5, minZoom)
            lastZoomScale = zoomScale
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

            // Calculate direction unit vector
            let dirX = dx / currentDistance
            let dirY = dy / currentDistance

            // New distance in points
            let newDistance = CGFloat(newLengthInches) * scale

            // New end point
            let newEnd = CGPoint(
                x: start.x + dirX * newDistance,
                y: start.y + dirY * newDistance
            )

            // Calculate how much to shift all subsequent points
            let shiftX = newEnd.x - end.x
            let shiftY = newEnd.y - end.y

            // Update the end point of this segment
            pipePoints[segment + 1].position = newEnd
            pipePoints[segment].measurementType = editMeasurementType

            // Shift all subsequent points
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
    }

    func breakSegment(at segmentIndex: Int, tapLocation: CGPoint) {
        guard segmentIndex < pipePoints.count - 1 else { return }

        let start = pipePoints[segmentIndex].position
        let end = pipePoints[segmentIndex + 1].position

        // Find the closest point on the line segment to the tap location
        let breakPoint = closestPointOnSegment(from: start, to: end, point: tapLocation)

        // Insert the new point
        let newPipePoint = PipePoint(position: breakPoint, fittingType: .none)
        pipePoints.insert(newPipePoint, at: segmentIndex + 1)

        // Turn off break mode after breaking
        breakModeEnabled = false

        // Automatically show fitting picker for the new point
        selectedPointIndex = segmentIndex + 1
        showingFittingPicker = true
    }

    func closestPointOnSegment(from start: CGPoint, to end: CGPoint, point: CGPoint) -> CGPoint {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy

        if lengthSquared == 0 {
            return start
        }

        // Calculate parameter t for the projection
        var t = ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared

        // Clamp t to [0, 1] to stay on the segment
        t = max(0, min(1, t))

        return CGPoint(
            x: start.x + t * dx,
            y: start.y + t * dy
        )
    }

    // Parse measurement string like "4'6-1/2" into total inches
    func parseMeasurement(_ input: String) -> Double? {
        var totalInches: Double = 0
        var remaining = input.trimmingCharacters(in: .whitespaces)

        // Remove trailing " if present
        if remaining.hasSuffix("\"") {
            remaining = String(remaining.dropLast())
        }

        // Check for feet (')
        if let feetIndex = remaining.firstIndex(of: "'") {
            let feetStr = String(remaining[..<feetIndex])
            if let feet = Double(feetStr) {
                totalInches += feet * 12
            }
            remaining = String(remaining[remaining.index(after: feetIndex)...])
        }

        // Now parse inches and fraction
        // Format could be: "6", "6-1/2", "1/2"
        if remaining.isEmpty {
            return totalInches > 0 ? totalInches : nil
        }

        // Check for fraction with hyphen (e.g., "6-1/2")
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
            // Just a fraction like "1/2"
            if let fraction = parseFraction(remaining) {
                totalInches += fraction
            }
        } else {
            // Just whole inches
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
    }

    func addOletToSegment(at segmentIndex: Int, tapLocation: CGPoint) {
        guard segmentIndex < pipePoints.count - 1 else { return }

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
        showingOletPicker = true
        oletModeEnabled = false
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
}

// MARK: - Index to Letter Conversion

func indexToLetter(_ index: Int) -> String {
    let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    if index < letters.count {
        return String(letters[letters.index(letters.startIndex, offsetBy: index)])
    }
    // For indices beyond 26, use AA, AB, etc.
    let first = index / 26 - 1
    let second = index % 26
    if first >= 0 && first < letters.count {
        return String(letters[letters.index(letters.startIndex, offsetBy: first)]) +
               String(letters[letters.index(letters.startIndex, offsetBy: second)])
    }
    return "\(index + 1)"
}

// MARK: - Feet-Inches Formatting

func formatFeetInches(inches: CGFloat) -> String {
    let feet = Int(inches / 12)
    let remainingInches = inches.truncatingRemainder(dividingBy: 12)
    let inchesFormatted = formatInchesWithFraction(remainingInches)

    if feet > 0 {
        if inchesFormatted.isEmpty || inchesFormatted == "0\"" {
            return "\(feet)'"
        }
        return "\(feet)'\(inchesFormatted)"
    } else {
        return inchesFormatted
    }
}

func formatInchesWithFraction(_ inches: CGFloat) -> String {
    let wholeInches = Int(inches)
    let fractionalPart = inches - CGFloat(wholeInches)

    // Convert to nearest 1/16th
    let sixteenths = Int(round(fractionalPart * 16))

    if sixteenths == 0 {
        return "\(wholeInches)\""
    } else if sixteenths == 16 {
        return "\(wholeInches + 1)\""
    }

    // Reduce the fraction
    let (numerator, denominator) = reduceFraction(sixteenths, 16)

    if wholeInches == 0 {
        return "\(numerator)/\(denominator)\""
    } else {
        return "\(wholeInches)-\(numerator)/\(denominator)\""
    }
}

func reduceFraction(_ num: Int, _ den: Int) -> (Int, Int) {
    let gcd = gcdFunc(num, den)
    return (num / gcd, den / gcd)
}

func gcdFunc(_ a: Int, _ b: Int) -> Int {
    if b == 0 { return a }
    return gcdFunc(b, a % b)
}

// MARK: - Measurement Keypad

struct MeasurementKeypad: View {
    @Binding var value: String
    @Binding var measurementType: String?
    let segmentNumber: Int
    let onCancel: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Button("Cancel") { onCancel() }
                    .foregroundColor(.red)
                Spacer()
                Text("Segment \(segmentNumber)")
                    .font(.headline)
                Spacer()
                Button("Save") { onSubmit() }
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)

            // Measurement Type Selector
            HStack(spacing: 8) {
                Text("Measurement Type:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(["F-C", "E-C", "C-C"], id: \.self) { type in
                    let isSelected = measurementType == type
                    Button(action: {
                        measurementType = type
                    }) {
                        Text(type)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.blue : Color(.systemGray5))
                            .foregroundColor(isSelected ? .white : .primary)
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal)

            // Display
            VStack(spacing: 4) {
                Text(value.isEmpty ? "0" : value)
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                if let type = measurementType {
                    Text(type)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            // Keypad
            VStack(spacing: 8) {
                // Row 1: 1 2 3
                HStack(spacing: 8) {
                    NumberButton("1") { value += "1" }
                    NumberButton("2") { value += "2" }
                    NumberButton("3") { value += "3" }
                }

                // Row 2: 4 5 6
                HStack(spacing: 8) {
                    NumberButton("4") { value += "4" }
                    NumberButton("5") { value += "5" }
                    NumberButton("6") { value += "6" }
                }

                // Row 3: 7 8 9
                HStack(spacing: 8) {
                    NumberButton("7") { value += "7" }
                    NumberButton("8") { value += "8" }
                    NumberButton("9") { value += "9" }
                }

                // Row 4: - 0 /
                HStack(spacing: 8) {
                    SpecialButton("-") { value += "-" }
                    NumberButton("0") { value += "0" }
                    SpecialButton("/") { value += "/" }
                }

                // Row 5: FT  ⌫  INCH
                HStack(spacing: 8) {
                    ActionButton("FT", color: .blue) { value += "'" }
                    ActionButton("⌫", color: .gray) {
                        if !value.isEmpty {
                            value.removeLast()
                        }
                    }
                    ActionButton("INCH", color: .green) {
                        value += "\""
                        onSubmit()
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: 400) // Limit width on iPad
        .frame(maxWidth: .infinity) // Center it
    }
}

struct NumberButton: View {
    let label: String
    let action: () -> Void

    init(_ label: String, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 22, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(.systemGray5))
                .cornerRadius(8)
        }
        .foregroundColor(.primary)
    }
}

struct SpecialButton: View {
    let label: String
    let action: () -> Void

    init(_ label: String, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 22, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(.systemGray4))
                .cornerRadius(8)
        }
        .foregroundColor(.primary)
    }
}

struct ActionButton: View {
    let label: String
    let color: Color
    let action: () -> Void

    init(_ label: String, color: Color, action: @escaping () -> Void) {
        self.label = label
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(color)
                .cornerRadius(8)
        }
        .foregroundColor(.white)
    }
}


// MARK: - Pipe Segment View

struct PipeSegmentView: View {
    let segmentIndex: Int
    let start: CGPoint
    let end: CGPoint
    let scale: CGFloat
    let zoomScale: CGFloat
    let measurementType: String?
    let pipeSize: PipeSize
    @Binding var dimensionLabelOffset: CGSize?
    @Binding var sizeLabelOffset: CGSize?
    @Binding var isDraggingAnyLabel: Bool  // Shared state to disable panning
    let breakModeEnabled: Bool
    let oletModeEnabled: Bool
    let onTapMeasurement: (Int) -> Void
    let onTapPipeSize: (Int) -> Void
    let onTapLine: (Int, CGPoint) -> Void

    // Drag state
    @State private var isDraggingDimension = false
    @State private var isDraggingSize = false
    @State private var dragStartOffset: CGSize = .zero

    var length: CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        return sqrt(dx * dx + dy * dy)
    }

    var midpoint: CGPoint {
        CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
    }

    // Default offset distances
    var defaultDimensionOffset: CGSize {
        CGSize(width: 0, height: -50 / zoomScale)
    }

    var defaultSizeOffset: CGSize {
        CGSize(width: 0, height: 30 / zoomScale)
    }

    // Actual offsets (custom or default)
    var actualDimensionOffset: CGSize {
        if let custom = dimensionLabelOffset {
            return CGSize(width: custom.width / zoomScale, height: custom.height / zoomScale)
        }
        return defaultDimensionOffset
    }

    var actualSizeOffset: CGSize {
        if let custom = sizeLabelOffset {
            return CGSize(width: custom.width / zoomScale, height: custom.height / zoomScale)
        }
        return defaultSizeOffset
    }

    // Position for dimension label
    var dimensionLabelPosition: CGPoint {
        CGPoint(
            x: midpoint.x + actualDimensionOffset.width,
            y: midpoint.y + actualDimensionOffset.height
        )
    }

    // Position for size label
    var sizeLabelPosition: CGPoint {
        CGPoint(
            x: midpoint.x + actualSizeOffset.width,
            y: midpoint.y + actualSizeOffset.height
        )
    }

    var body: some View {
        ZStack {
            // Pipe line - tappable in break mode or olet mode
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(breakModeEnabled ? Color.orange : (oletModeEnabled ? Color.purple : Color.green), lineWidth: 2.5)
            .shadow(radius: 2)
            .contentShape(Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }.strokedPath(StrokeStyle(lineWidth: 30)))
            .onTapGesture { location in
                if breakModeEnabled || oletModeEnabled {
                    onTapLine(segmentIndex, location)
                }
            }

            // Curved leader line to dimension label
            Path { path in
                path.move(to: midpoint)
                let labelBottom = CGPoint(
                    x: dimensionLabelPosition.x,
                    y: dimensionLabelPosition.y + (15 / zoomScale)
                )
                let controlPoint = CGPoint(
                    x: (midpoint.x + labelBottom.x) / 2,
                    y: (midpoint.y + labelBottom.y) / 2
                )
                path.addQuadCurve(to: labelBottom, control: controlPoint)
            }
            .stroke(Color.gray.opacity(0.5), lineWidth: 1)

            // Dimension label - draggable
            VStack(spacing: 2) {
                Text(formatFeetInches(inches: length / scale))
                    .font(.system(size: 14, weight: .bold))
                if let type = measurementType {
                    Text(type)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .foregroundColor(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isDraggingDimension ? Color.yellow.opacity(0.95) : Color.white.opacity(0.95))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isDraggingDimension ? Color.orange : Color.blue.opacity(0.3), lineWidth: isDraggingDimension ? 2 : 1)
            )
            .scaleEffect(1 / zoomScale)
            .position(dimensionLabelPosition)
            .highPriorityGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { drag in
                        if !isDraggingDimension {
                            isDraggingDimension = true
                            isDraggingAnyLabel = true  // Disable panning
                            dragStartOffset = dimensionLabelOffset ?? CGSize(width: 0, height: -50)
                        }
                        dimensionLabelOffset = CGSize(
                            width: dragStartOffset.width + drag.translation.width,
                            height: dragStartOffset.height + drag.translation.height
                        )
                    }
                    .onEnded { _ in
                        isDraggingDimension = false
                        isDraggingAnyLabel = false  // Re-enable panning
                    }
            )
            .onTapGesture {
                if !breakModeEnabled {
                    onTapMeasurement(segmentIndex)
                }
            }

            // Curved leader line to size label
            Path { path in
                path.move(to: midpoint)
                let labelTop = CGPoint(
                    x: sizeLabelPosition.x,
                    y: sizeLabelPosition.y - (10 / zoomScale)
                )
                let controlPoint = CGPoint(
                    x: (midpoint.x + labelTop.x) / 2,
                    y: (midpoint.y + labelTop.y) / 2
                )
                path.addQuadCurve(to: labelTop, control: controlPoint)
            }
            .stroke(Color.gray.opacity(0.5), lineWidth: 1)

            // Pipe size label - draggable
            Text(pipeSize == .none ? "Size?" : pipeSize.shortName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(pipeSize == .none ? .gray : .white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isDraggingSize ? Color.yellow.opacity(0.9) : (pipeSize == .none ? Color.white.opacity(0.9) : Color.purple.opacity(0.9)))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isDraggingSize ? Color.orange : (pipeSize == .none ? Color.gray.opacity(0.3) : Color.purple), lineWidth: isDraggingSize ? 2 : 1)
                )
                .scaleEffect(1 / zoomScale)
                .position(sizeLabelPosition)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { drag in
                            if !isDraggingSize {
                                isDraggingSize = true
                                isDraggingAnyLabel = true  // Disable panning
                                dragStartOffset = sizeLabelOffset ?? CGSize(width: 0, height: 30)
                            }
                            sizeLabelOffset = CGSize(
                                width: dragStartOffset.width + drag.translation.width,
                                height: dragStartOffset.height + drag.translation.height
                            )
                        }
                        .onEnded { _ in
                            isDraggingSize = false
                            isDraggingAnyLabel = false  // Re-enable panning
                        }
                )
                .onTapGesture {
                    if !breakModeEnabled {
                        onTapPipeSize(segmentIndex)
                    }
                }
        }
    }
}

// MARK: - Point Marker View

struct PointMarkerView: View {
    let index: Int
    let isFirst: Bool
    let isLast: Bool
    let fittingType: FittingType
    let fittingOrientation: CGFloat?  // Branch direction for tee fittings
    let hasBranch: Bool  // Whether this tee has a branch connected
    let position: CGPoint  // Absolute position of the point
    let zoomScale: CGFloat
    @Binding var bubbleLabelOffset: CGSize?
    @Binding var isDraggingAnyLabel: Bool
    let onTap: () -> Void

    @State private var isDraggingBubble = false
    @State private var dragStartOffset: CGSize = .zero

    var color: Color {
        if isFirst { return .green }
        if isLast { return .red }
        if fittingType != .none { return .blue }
        return .orange
    }

    // Actual offset (custom or default at point position)
    var actualBubbleOffset: CGSize {
        if let custom = bubbleLabelOffset {
            return CGSize(width: custom.width / zoomScale, height: custom.height / zoomScale)
        }
        return .zero
    }

    // Check if bubble has been moved from default position
    var hasOffset: Bool {
        guard let offset = bubbleLabelOffset else { return false }
        return abs(offset.width) > 1 || abs(offset.height) > 1
    }

    var body: some View {
        ZStack {
            // Leader line (only shown when bubble has been moved)
            if hasOffset {
                Path { path in
                    path.move(to: position)
                    let labelPoint = CGPoint(
                        x: position.x + actualBubbleOffset.width,
                        y: position.y + actualBubbleOffset.height
                    )
                    let controlPoint = CGPoint(
                        x: (position.x + labelPoint.x) / 2,
                        y: (position.y + labelPoint.y) / 2
                    )
                    path.addQuadCurve(to: labelPoint, control: controlPoint)
                }
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            }

            // Branch indicator line for tee fittings
            if fittingType == .tee, let orientation = fittingOrientation {
                Path { path in
                    let angle = orientation * .pi / 180
                    let startX = position.x + actualBubbleOffset.width
                    let startY = position.y + actualBubbleOffset.height
                    let lineLength: CGFloat = 18 / zoomScale
                    let endX = startX + cos(angle) * lineLength
                    let endY = startY - sin(angle) * lineLength
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
                .stroke(hasBranch ? Color.green : Color.blue, lineWidth: 2.5 / zoomScale)
            }

            // Bubble content
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(isDraggingBubble ? Color.orange : Color.clear, lineWidth: 2)
                        )

                    if fittingType != .none {
                        if fittingType == .tee, let orientation = fittingOrientation {
                            // Rotated tee symbol with branch indicator
                            Text(fittingType.symbol)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(orientation - 90))  // Normalize to 0° = right
                        } else {
                            Text(fittingType.symbol)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    } else {
                        Text("\(index + 1)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                if fittingType != .none {
                    Text(fittingType.rawValue)
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .scaleEffect(1 / zoomScale)
            .position(
                x: position.x + actualBubbleOffset.width,
                y: position.y + actualBubbleOffset.height
            )
            .highPriorityGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { drag in
                        if !isDraggingBubble {
                            isDraggingBubble = true
                            isDraggingAnyLabel = true
                            dragStartOffset = bubbleLabelOffset ?? .zero
                        }
                        bubbleLabelOffset = CGSize(
                            width: dragStartOffset.width + drag.translation.width,
                            height: dragStartOffset.height + drag.translation.height
                        )
                    }
                    .onEnded { _ in
                        isDraggingBubble = false
                        isDraggingAnyLabel = false
                    }
            )
            .onTapGesture {
                onTap()
            }
        }
    }
}

// MARK: - Segment Bubble View (Letter bubbles for pipe segments)

struct SegmentBubbleView: View {
    let segmentIndex: Int
    let midpoint: CGPoint
    let zoomScale: CGFloat
    @Binding var segmentBubbleOffset: CGSize?
    @Binding var isDraggingAnyLabel: Bool

    @State private var isDraggingBubble = false
    @State private var dragStartOffset: CGSize = .zero

    // Actual offset (custom or default at midpoint)
    var actualBubbleOffset: CGSize {
        if let custom = segmentBubbleOffset {
            return CGSize(width: custom.width / zoomScale, height: custom.height / zoomScale)
        }
        return .zero
    }

    // Check if bubble has been moved from default position
    var hasOffset: Bool {
        guard let offset = segmentBubbleOffset else { return false }
        return abs(offset.width) > 1 || abs(offset.height) > 1
    }

    var body: some View {
        ZStack {
            // Leader line (only shown when bubble has been moved)
            if hasOffset {
                Path { path in
                    path.move(to: midpoint)
                    let labelPoint = CGPoint(
                        x: midpoint.x + actualBubbleOffset.width,
                        y: midpoint.y + actualBubbleOffset.height
                    )
                    let controlPoint = CGPoint(
                        x: (midpoint.x + labelPoint.x) / 2,
                        y: (midpoint.y + labelPoint.y) / 2
                    )
                    path.addQuadCurve(to: labelPoint, control: controlPoint)
                }
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            }

            // Bubble content
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(isDraggingBubble ? Color.orange : Color.blue, lineWidth: 2)
                    )

                Text(indexToLetter(segmentIndex))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.blue)
            }
            .scaleEffect(1 / zoomScale)
            .position(
                x: midpoint.x + actualBubbleOffset.width,
                y: midpoint.y + actualBubbleOffset.height
            )
            .highPriorityGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { drag in
                        if !isDraggingBubble {
                            isDraggingBubble = true
                            isDraggingAnyLabel = true
                            dragStartOffset = segmentBubbleOffset ?? .zero
                        }
                        segmentBubbleOffset = CGSize(
                            width: dragStartOffset.width + drag.translation.width,
                            height: dragStartOffset.height + drag.translation.height
                        )
                    }
                    .onEnded { _ in
                        isDraggingBubble = false
                        isDraggingAnyLabel = false
                    }
            )
        }
    }
}

// MARK: - Fitting Type Picker

struct FittingTypePicker: View {
    let selectedType: FittingType
    let selectedOrientation: CGFloat?
    let pointNumber: Int
    let isEndPoint: Bool  // true if first or last point
    let onSelect: (FittingType, CGFloat?) -> Void
    let onCancel: () -> Void

    @State private var tempSelectedType: FittingType
    @State private var tempOrientation: CGFloat = 90  // Default to 90° (up)

    // Fittings only allowed at end points (caps can't be in middle of pipe run)
    let endPointOnlyFittings: [FittingType] = [.cap]

    init(selectedType: FittingType, selectedOrientation: CGFloat? = nil, pointNumber: Int, isEndPoint: Bool, onSelect: @escaping (FittingType, CGFloat?) -> Void, onCancel: @escaping () -> Void) {
        self.selectedType = selectedType
        self.selectedOrientation = selectedOrientation
        self.pointNumber = pointNumber
        self.isEndPoint = isEndPoint
        self.onSelect = onSelect
        self.onCancel = onCancel
        self._tempSelectedType = State(initialValue: selectedType)
        self._tempOrientation = State(initialValue: selectedOrientation ?? 90)
    }

    var availableFittings: [FittingType] {
        if isEndPoint {
            return FittingType.allCases
        } else {
            // Filter out fittings that can only be at end points
            return FittingType.allCases.filter { !endPointOnlyFittings.contains($0) }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Button("Cancel") { onCancel() }
                Spacer()
                Text("Point \(pointNumber) Fitting")
                    .font(.headline)
                Spacer()
                Button("Cancel") { onCancel() }
                    .opacity(0)
            }
            .padding(.horizontal)

            if !isEndPoint {
                Text("Note: Caps only available at end points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Fitting options
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(availableFittings, id: \.self) { fitting in
                    Button(action: { tempSelectedType = fitting }) {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(tempSelectedType == fitting ? Color.blue : Color(.systemGray5))
                                    .frame(width: 50, height: 50)

                                if fitting != .none {
                                    Text(fitting.symbol)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(tempSelectedType == fitting ? .white : .primary)
                                } else {
                                    Image(systemName: "minus")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(tempSelectedType == fitting ? .white : .primary)
                                }
                            }

                            Text(fitting.rawValue)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.horizontal)

            // Orientation selector (only shown for tee fittings)
            if tempSelectedType == .tee {
                Divider()
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    Text("Branch Direction:")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    // 6 directional buttons in two rows
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            orientationButton(angle: 30, label: "↗ 30°")
                            orientationButton(angle: 90, label: "↑ 90°")
                            orientationButton(angle: 150, label: "↖ 150°")
                        }
                        HStack(spacing: 12) {
                            orientationButton(angle: 210, label: "↙ 210°")
                            orientationButton(angle: 270, label: "↓ 270°")
                            orientationButton(angle: 330, label: "↘ 330°")
                        }
                    }

                    // Visual preview of tee with orientation
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 60, height: 60)

                        Text("⊥")
                            .font(.system(size: 30, weight: .bold))
                            .rotationEffect(.degrees(tempOrientation - 90))

                        // Branch indicator line
                        Path { path in
                            let center = CGPoint(x: 30, y: 30)
                            let angle = tempOrientation * .pi / 180
                            let endX = center.x + cos(angle) * 25
                            let endY = center.y - sin(angle) * 25
                            path.move(to: center)
                            path.addLine(to: CGPoint(x: endX, y: endY))
                        }
                        .stroke(Color.blue, lineWidth: 3)
                    }
                    .frame(width: 60, height: 60)

                    Text("Tee preview with branch at \(Int(tempOrientation))°")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }

            // Done button
            Button(action: {
                onSelect(tempSelectedType, tempSelectedType == .tee ? tempOrientation : nil)
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom)

            Spacer()
        }
        .padding(.top)
    }

    @ViewBuilder
    private func orientationButton(angle: CGFloat, label: String) -> some View {
        Button(action: { tempOrientation = angle }) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(tempOrientation == angle ? .white : .primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(tempOrientation == angle ? Color.blue : Color(.systemGray5))
                .cornerRadius(8)
        }
    }
}

// MARK: - Pipe Size Picker

struct PipeSizePicker: View {
    let selectedSize: PipeSize
    let segmentNumber: Int
    let onSelect: (PipeSize) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Button("Cancel") { onCancel() }
                Spacer()
                Text("Segment \(segmentNumber) Pipe Size")
                    .font(.headline)
                Spacer()
                Button("Cancel") { onCancel() }
                    .opacity(0)
            }
            .padding(.horizontal)

            // Size options
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(PipeSize.allCases, id: \.self) { size in
                    Button(action: { onSelect(size) }) {
                        Text(size.shortName)
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedSize == size ? Color.purple : Color(.systemGray5))
                            .foregroundColor(selectedSize == size ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
    }
}

// MARK: - Bill of Materials View

struct BillOfMaterialsView: View {
    let pipePoints: [PipePoint]
    let scale: CGFloat
    let onDismiss: () -> Void

    // Fitting item for BOM
    struct FittingItem: Identifiable {
        let id = UUID()
        let fittingType: FittingType
        let enteringSize: PipeSize?
        let exitingSize: PipeSize?
        let branchSize: PipeSize?  // For tees: the branch outlet size
        let pointIndex: Int
        let isInferred: Bool  // true if elbow was auto-detected from direction change
    }

    // Pipe length item for BOM
    struct PipeLengthItem: Identifiable {
        let id = UUID()
        let pipeSize: PipeSize
        let totalLength: CGFloat  // in inches
    }

    // O'let item for BOM
    struct OletItem: Identifiable {
        let id = UUID()
        let oletType: OletType
        let pipeSize: PipeSize
        let outletSize: PipeSize
        let segmentIndex: Int
    }

    // Calculate the angle of a segment in degrees
    func segmentAngle(from start: CGPoint, to end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        var angle = atan2(-dy, dx) * 180 / .pi
        if angle < 0 { angle += 360 }
        return angle
    }

    // Calculate the turn angle at a point between two segments
    func turnAngle(incomingAngle: CGFloat, outgoingAngle: CGFloat) -> CGFloat {
        // Calculate the difference, accounting for the fact that continuing straight
        // would mean outgoing = incoming (same direction)
        var diff = outgoingAngle - incomingAngle
        // Normalize to -180 to 180
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return abs(diff)
    }

    // Determine elbow type from turn angle
    // In isometric: 60° turn on drawing = 90° elbow in 3D
    // 120° turn on drawing could be 90° in horizontal plane
    func inferredElbowType(turnAngle: CGFloat) -> FittingType {
        // Allow some tolerance for angle matching
        if turnAngle < 10 {
            return .none  // Straight through, no elbow needed
        } else if turnAngle >= 10 && turnAngle <= 75 {
            // ~45° to ~60° turn - treat as 90° elbow (common in isometric)
            return .elbow90
        } else if turnAngle > 75 && turnAngle <= 135 {
            // ~90° to ~120° turn - also 90° elbow
            return .elbow90
        } else {
            // Larger turns - still likely need 90° elbows (or multiple)
            return .elbow90
        }
    }

    var fittingItems: [FittingItem] {
        var items: [FittingItem] = []

        for (index, point) in pipePoints.enumerated() {
            let isFirst = index == 0
            let isLast = index == pipePoints.count - 1

            // Entering size is from the segment before this point
            let enteringSize: PipeSize? = isFirst ? nil : pipePoints[index - 1].pipeSize

            // Exiting size is from the segment after this point
            let exitingSize: PipeSize? = isLast ? nil : pipePoints[index].pipeSize

            // If user explicitly set a fitting, use it
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
            // For intermediate points, check for direction change (implied elbow)
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
            let dx = end.x - start.x
            let dy = end.y - start.y
            let lengthPts = sqrt(dx * dx + dy * dy)
            let lengthInches = lengthPts / scale

            let size = pipePoints[i].pipeSize
            lengthsBySize[size, default: 0] += lengthInches
        }

        // Sort by pipe size (using allCases order)
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

        for (index, point) in pipePoints.enumerated() {
            let pipeSize = point.pipeSize

            for olet in point.olets {
                items.append(OletItem(
                    oletType: olet.type,
                    pipeSize: pipeSize,
                    outletSize: olet.size,
                    segmentIndex: index
                ))
            }
        }

        return items
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
                return "\(entering) × \(branchSize)"  // Run same, branch different
            } else {
                return "\(entering) × \(exiting) × \(branchSize)"  // All different
            }
        }

        // End fittings show single size
        if item.enteringSize == nil {
            return exiting
        } else if item.exitingSize == nil {
            return entering
        }

        // Inline fittings show entering x exiting
        if item.enteringSize == item.exitingSize {
            return entering  // Same size, just show one
        } else {
            return "\(entering) × \(exiting)"
        }
    }

    var body: some View {
        NavigationView {
            List {
                // Fittings Section
                if !fittingItems.isEmpty {
                    Section(header: Text("Fittings")) {
                        ForEach(fittingItems) { item in
                            HStack {
                                // Fitting symbol - orange if inferred, blue if explicit
                                ZStack {
                                    Circle()
                                        .fill(item.isInferred ? Color.orange : Color.blue)
                                        .frame(width: 32, height: 32)
                                    Text(item.fittingType.symbol)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(item.fittingType.rawValue)
                                            .font(.body)
                                        if item.isInferred {
                                            Text("(auto)")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    Text("Point \(item.pointIndex + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                // Size
                                Text(formatFittingSize(item))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }

                // O'lets Section
                if !oletItems.isEmpty {
                    Section(header: Text("O'lets")) {
                        ForEach(oletItems) { item in
                            HStack {
                                // O'let symbol
                                ZStack {
                                    Circle()
                                        .fill(Color.purple)
                                        .frame(width: 32, height: 32)
                                    Text(item.oletType.symbol)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.oletType.rawValue)
                                        .font(.body)
                                    Text("Segment \(item.segmentIndex + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                // Pipe size × Outlet size
                                Text("\(item.pipeSize.shortName) × \(item.outletSize.shortName)")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }

                // Pipe Lengths Section
                if !pipeLengthItems.isEmpty {
                    Section(header: Text("Pipe Lengths")) {
                        ForEach(pipeLengthItems) { item in
                            HStack {
                                Text(item.pipeSize == .none ? "Unspecified" : item.pipeSize.shortName)
                                    .font(.body)

                                Spacer()

                                Text(formatFeetInches(inches: item.totalLength))
                                    .font(.system(.body, design: .monospaced))
                            }
                        }

                        // Total
                        HStack {
                            Text("Total")
                                .font(.headline)

                            Spacer()

                            Text(formatFeetInches(inches: totalPipeLength))
                                .font(.system(.headline, design: .monospaced))
                        }
                    }
                }

                // Summary Section
                Section(header: Text("Summary")) {
                    HStack {
                        Text("Total Points")
                        Spacer()
                        Text("\(pipePoints.count)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Total Segments")
                        Spacer()
                        Text("\(max(0, pipePoints.count - 1))")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Total Fittings")
                        Spacer()
                        Text("\(fittingItems.count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Bill of Materials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Legacy Point Marker (unused)

struct PointMarker: View {
    let index: Int
    let isFirst: Bool
    let isLast: Bool

    var color: Color {
        if isFirst { return .green }
        if isLast { return .red }
        return .orange
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)

            Text("\(index + 1)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - O'let Marker View

struct OletMarkerView: View {
    let olet: Olet
    let segmentStart: CGPoint
    let segmentEnd: CGPoint
    let zoomScale: CGFloat
    let scale: CGFloat
    @Binding var dimensionLabelOffset: CGSize?
    @Binding var isDraggingAnyLabel: Bool
    let onTap: () -> Void
    let onTapDimension: () -> Void

    @State private var isDraggingDimension = false
    @State private var dragStartOffset: CGSize = .zero

    // Calculate distance from segment start to olet position in inches
    var distanceFromStart: CGFloat {
        let dx = segmentEnd.x - segmentStart.x
        let dy = segmentEnd.y - segmentStart.y
        let segmentLength = sqrt(dx * dx + dy * dy)
        let distanceInPoints = segmentLength * olet.position
        return distanceInPoints / scale
    }

    // Default offset for dimension label
    var defaultDimensionOffset: CGSize {
        CGSize(width: 0, height: 30 / zoomScale)
    }

    // Actual offset (custom or default)
    var actualDimensionOffset: CGSize {
        if let custom = dimensionLabelOffset {
            return CGSize(width: custom.width / zoomScale, height: custom.height / zoomScale)
        }
        return defaultDimensionOffset
    }

    // Check if label has been moved
    var hasOffset: Bool {
        guard let offset = dimensionLabelOffset else { return false }
        return abs(offset.width) > 1 || abs(offset.height) > 1
    }

    var body: some View {
        let position = CGPoint(
            x: segmentStart.x + (segmentEnd.x - segmentStart.x) * olet.position,
            y: segmentStart.y + (segmentEnd.y - segmentStart.y) * olet.position
        )

        // Calculate segment angle for orientation
        let dx = segmentEnd.x - segmentStart.x
        let dy = segmentEnd.y - segmentStart.y
        let segmentAngle = atan2(dy, dx) * 180 / .pi

        let dimensionPosition = CGPoint(
            x: position.x + actualDimensionOffset.width,
            y: position.y + actualDimensionOffset.height
        )

        ZStack {
            // Leader line to dimension label (only when offset)
            if hasOffset {
                Path { path in
                    path.move(to: position)
                    let controlPoint = CGPoint(
                        x: (position.x + dimensionPosition.x) / 2,
                        y: (position.y + dimensionPosition.y) / 2
                    )
                    path.addQuadCurve(to: dimensionPosition, control: controlPoint)
                }
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            }

            // O'let symbol (tappable)
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)

                Circle()
                    .stroke(Color.purple, lineWidth: 2)
                    .frame(width: 24, height: 24)

                Text(olet.type.symbol)
                    .font(.system(size: 16))
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
            .position(position)
            .onTapGesture {
                onTap()
            }

            // Orientation indicator (arrow)
            Path { path in
                let arrowLength: CGFloat = 20
                let arrowAngle = segmentAngle + olet.orientation
                let radians = arrowAngle * .pi / 180

                let endX = arrowLength * cos(radians)
                let endY = arrowLength * sin(radians)

                path.move(to: .zero)
                path.addLine(to: CGPoint(x: endX, y: endY))

                // Arrow head
                let headAngle1 = (arrowAngle - 150) * .pi / 180
                let headAngle2 = (arrowAngle + 150) * .pi / 180
                let headLength: CGFloat = 8

                path.move(to: CGPoint(x: endX, y: endY))
                path.addLine(to: CGPoint(
                    x: endX + headLength * cos(headAngle1),
                    y: endY + headLength * sin(headAngle1)
                ))

                path.move(to: CGPoint(x: endX, y: endY))
                path.addLine(to: CGPoint(
                    x: endX + headLength * cos(headAngle2),
                    y: endY + headLength * sin(headAngle2)
                ))
            }
            .stroke(Color.purple, lineWidth: 2)
            .position(position)

            // Dimension label - draggable and tappable
            Text(formatFeetInches(inches: distanceFromStart))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.purple)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(isDraggingDimension ? Color.yellow.opacity(0.95) : Color.white.opacity(0.95))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isDraggingDimension ? Color.orange : Color.purple.opacity(0.5), lineWidth: isDraggingDimension ? 2 : 1)
                )
                .scaleEffect(1 / zoomScale)
                .position(dimensionPosition)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { drag in
                            if !isDraggingDimension {
                                isDraggingDimension = true
                                isDraggingAnyLabel = true
                                dragStartOffset = dimensionLabelOffset ?? CGSize(width: 0, height: 30)
                            }
                            dimensionLabelOffset = CGSize(
                                width: dragStartOffset.width + drag.translation.width,
                                height: dragStartOffset.height + drag.translation.height
                            )
                        }
                        .onEnded { _ in
                            isDraggingDimension = false
                            isDraggingAnyLabel = false
                        }
                )
                .onTapGesture {
                    onTapDimension()
                }
        }
    }
}

// MARK: - Isometric Grid View

struct IsometricGridView: View {
    let allowedAngles: [CGFloat]
    let gridSpacing: CGFloat = 30

    // Grid extends far enough to cover zoomed-out views (10x screen size in each direction)
    let gridMultiplier: CGFloat = 10

    var body: some View {
        Canvas { context, size in
            let lineColor = Color.gray.opacity(0.3)
            let maxDimension = max(size.width, size.height) * gridMultiplier
            let centerX = size.width / 2
            let centerY = size.height / 2

            // Vertical lines (90° / 270°) extending across entire grid
            var x: CGFloat = centerX
            while x < centerX + maxDimension {
                var path = Path()
                path.move(to: CGPoint(x: x, y: centerY - maxDimension))
                path.addLine(to: CGPoint(x: x, y: centerY + maxDimension))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                x += gridSpacing
            }
            x = centerX - gridSpacing
            while x > centerX - maxDimension {
                var path = Path()
                path.move(to: CGPoint(x: x, y: centerY - maxDimension))
                path.addLine(to: CGPoint(x: x, y: centerY + maxDimension))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                x -= gridSpacing
            }

            // 30° lines (NW/SE direction) - lines go from lower-left to upper-right
            // Spacing perpendicular to the line direction
            let angle30 = 30.0 * .pi / 180.0
            let perpSpacing30 = gridSpacing / sin(60.0 * .pi / 180.0)  // perpendicular distance

            // We need to offset along the X axis and draw lines that extend in both Y directions
            // Each line passes through a point at the center Y level
            let lineLength = maxDimension * 4

            var offset30: CGFloat = -maxDimension * 2
            while offset30 < maxDimension * 2 {
                // Point on the center horizontal line
                let anchorX = centerX + offset30
                let anchorY = centerY

                // Extend in both directions along the 30° angle
                let halfLen = lineLength / 2
                let dx30 = cos(angle30)
                let dy30 = -sin(angle30)  // negative because Y increases downward

                let startX = anchorX - halfLen * dx30
                let startY = anchorY - halfLen * dy30
                let endX = anchorX + halfLen * dx30
                let endY = anchorY + halfLen * dy30

                var path = Path()
                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)

                offset30 += perpSpacing30
            }

            // 150° lines (NE/SW direction) - lines go from lower-right to upper-left
            let angle150 = 150.0 * .pi / 180.0
            let perpSpacing150 = gridSpacing / sin(60.0 * .pi / 180.0)  // same perpendicular distance

            var offset150: CGFloat = -maxDimension * 2
            while offset150 < maxDimension * 2 {
                // Point on the center horizontal line
                let anchorX = centerX + offset150
                let anchorY = centerY

                // Extend in both directions along the 150° angle
                let halfLen = lineLength / 2
                let dx150 = cos(angle150)
                let dy150 = -sin(angle150)  // negative because Y increases downward

                let startX = anchorX - halfLen * dx150
                let startY = anchorY - halfLen * dy150
                let endX = anchorX + halfLen * dx150
                let endY = anchorY + halfLen * dy150

                var path = Path()
                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)

                offset150 += perpSpacing150
            }
        }
    }
}

// MARK: - O'let Picker

struct OletPicker: View {
    let selectedType: OletType
    let selectedOrientation: CGFloat
    let selectedSize: PipeSize
    let onSelect: (OletType, CGFloat, PipeSize) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    @State private var currentType: OletType
    @State private var currentOrientation: CGFloat
    @State private var currentSize: PipeSize
    @State private var showingDeleteConfirmation: Bool = false

    // Isometric angles for o'let orientation
    let allowedAngles: [CGFloat] = [30, 90, 150, 210, 270, 330]

    init(selectedType: OletType, selectedOrientation: CGFloat, selectedSize: PipeSize, onSelect: @escaping (OletType, CGFloat, PipeSize) -> Void, onDelete: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.selectedType = selectedType
        self.selectedOrientation = selectedOrientation
        self.selectedSize = selectedSize
        self.onSelect = onSelect
        self.onDelete = onDelete
        self.onCancel = onCancel
        _currentType = State(initialValue: selectedType)
        _currentOrientation = State(initialValue: selectedOrientation)
        _currentSize = State(initialValue: selectedSize)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("O'let Type")) {
                    ForEach(OletType.allCases, id: \.self) { type in
                        HStack {
                            Text(type.symbol)
                                .font(.system(size: 24))
                            Text(type.rawValue)
                                .font(.body)
                            Spacer()
                            if type == currentType {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.purple)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            currentType = type
                        }
                    }
                }

                Section(header: Text("Outlet Size")) {
                    ForEach(PipeSize.allCases.filter { $0 != .none }, id: \.self) { size in
                        HStack {
                            Text(size.rawValue)
                            Spacer()
                            if size == currentSize {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.purple)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            currentSize = size
                        }
                    }
                }

                Section(header: Text("Orientation (Isometric Angle)")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                        ForEach(allowedAngles, id: \.self) { angle in
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .stroke(currentOrientation == angle ? Color.purple : Color.gray, lineWidth: 2)
                                        .frame(width: 50, height: 50)

                                    // Arrow showing direction
                                    Path { path in
                                        let radians = angle * .pi / 180
                                        let length: CGFloat = 18
                                        let endX = length * cos(radians)
                                        let endY = length * sin(radians)

                                        path.move(to: .zero)
                                        path.addLine(to: CGPoint(x: endX, y: endY))

                                        // Arrow head
                                        let headAngle1 = (angle - 150) * .pi / 180
                                        let headAngle2 = (angle + 150) * .pi / 180
                                        let headLength: CGFloat = 6

                                        path.move(to: CGPoint(x: endX, y: endY))
                                        path.addLine(to: CGPoint(
                                            x: endX + headLength * cos(headAngle1),
                                            y: endY + headLength * sin(headAngle1)
                                        ))

                                        path.move(to: CGPoint(x: endX, y: endY))
                                        path.addLine(to: CGPoint(
                                            x: endX + headLength * cos(headAngle2),
                                            y: endY + headLength * sin(headAngle2)
                                        ))
                                    }
                                    .stroke(currentOrientation == angle ? Color.purple : Color.gray, lineWidth: 2)
                                }

                                Text("\(Int(angle))°")
                                    .font(.caption)
                                    .foregroundColor(currentOrientation == angle ? .purple : .gray)
                            }
                            .onTapGesture {
                                currentOrientation = angle
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Configure O'let")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSelect(currentType, currentOrientation, currentSize)
                    }
                    .fontWeight(.bold)
                }
            }
            .alert("Delete O'let?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("This will remove the o'let from the pipe segment.")
            }
        }
    }
}

#Preview {
    ContentView()
}
