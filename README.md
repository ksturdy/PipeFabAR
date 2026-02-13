# PipeRouterAR

AR-based pipe routing for mechanical rooms. Scan a space with LiDAR, place start/end points, and generate an optimal pipe route that avoids obstacles.

## Requirements

- **Device**: iPhone 12 Pro or newer, iPad Pro (2020+) with LiDAR
- **iOS**: 17.0+
- **Xcode**: 15.0+
- **Mac**: Required for building and deploying

## Quick Start

1. Open `PipeRouterAR.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Connect a LiDAR-equipped device
4. Build and run (⌘R)

## How It Works

### 1. Room Scanning
The app uses ARKit's Scene Reconstruction to build a 3D mesh of your environment in real-time. The purple wireframe overlay shows what the LiDAR has captured.

### 2. Point Placement
Tap anywhere on a scanned surface to place route points:
- First tap = Start point (green)
- Second tap = End point (red)

### 3. Route Calculation
The A* pathfinding algorithm finds the optimal route:
- Orthogonal movements only (X, Y, Z axes)
- Avoids detected obstacles
- Minimizes bends (each bend adds cost)
- 10cm grid resolution

### 4. Visualization
The calculated route appears as copper-colored pipes with yellow fittings at each bend.

### 5. Export
Basic text export of route segments, lengths, and fitting counts.

---

## Architecture

```
PipeRouterAR/
├── PipeRouterARApp.swift    # App entry point
├── ContentView.swift        # Main UI + AR view container
├── ARViewModel.swift        # State management + visualization
├── PipePathfinder.swift     # A* routing algorithm
└── Info.plist               # Permissions + device requirements
```

### Key Components

**ARViewContainer** (ContentView.swift)
- Wraps RealityKit's ARView for SwiftUI
- Configures AR session with scene reconstruction
- Handles tap gestures for point placement

**ARViewModel** 
- Manages application state
- Converts mesh anchors to obstacle grid
- Visualizes routes using RealityKit entities

**PipePathfinder**
- 3D A* implementation restricted to orthogonal movement
- Priority queue for efficient frontier expansion
- Path simplification to remove redundant waypoints

---

## What's Included vs. What You'd Add

### ✅ Included in this starter
- LiDAR room scanning with mesh visualization
- Tap-to-place start/end points
- Basic A* pathfinding with obstacle avoidance
- 3D pipe visualization in AR
- Simple text export

### 🚧 Next steps to build
- **RoomPlan integration** for cleaner room scans
- **Pipe size selection** (2", 4", 6", etc.)
- **Slope constraints** for drainage
- **Support spacing** calculations
- **Isometric drawing generation** (PDF/DXF export)
- **Material takeoff** with real pipe/fitting specs
- **Save/load** routes for later editing
- **Multi-route** support (multiple pipe runs)
- **Insulation clearance** calculations

---

## Pathfinding Details

The `PipePathfinder` uses a modified A* algorithm:

**Grid**: 10cm resolution (configurable)

**Movement**: 6 orthogonal directions only
- No diagonals (pipes don't run at 45°)

**Costs**:
- Straight movement: 1.0
- Direction change (bend): +2.0 penalty

**Heuristic**: Manhattan distance + estimated minimum bends

**Constraints**:
- Max route length: 20 meters
- Max iterations: 50,000

---

## Limitations

1. **LiDAR range**: ~5 meters effective. Large rooms need multiple scan positions.

2. **Reflective surfaces**: Chrome pipes, mirrors, and glass don't scan well.

3. **Dark surfaces**: Black equipment may not register accurately.

4. **Accuracy**: LiDAR gets within ~1-2cm. Good for conceptual routing, not fabrication.

5. **Routing intelligence**: Current algorithm only avoids obstacles. Real pipe routing has many more constraints (slope, support spacing, insulation, clearances, etc.).

---

## Extending the App

### Adding pipe size selection

```swift
// In ARViewModel
enum PipeSize: Float, CaseIterable {
    case twoInch = 0.0254    // 1" radius
    case fourInch = 0.0508   // 2" radius
    case sixInch = 0.0762    // 3" radius
    
    var displayName: String {
        switch self {
        case .twoInch: return "2\""
        case .fourInch: return "4\""
        case .sixInch: return "6\""
        }
    }
}

@Published var selectedPipeSize: PipeSize = .twoInch
```

### Adding slope for drainage

```swift
// In PipePathfinder
// Modify heuristic to prefer downward movement
private func heuristic(from: SIMD3<Int>, to: SIMD3<Int>, requireSlope: Bool) -> Float {
    var cost = manhattanDistance(from, to)
    
    if requireSlope {
        // Penalize upward movement
        if to.y > from.y {
            cost += 10.0  // Heavy penalty for going up
        }
    }
    
    return cost
}
```

### Generating isometric drawings

This would require a separate drawing engine. Options:
- Generate SVG/PDF using Core Graphics
- Export to DXF format for CAD software
- Use a library like SwiftDraw

---

## License

This is starter code for educational purposes. Use freely.
