import SwiftUI

@available(iOS 13.0, *)
public struct PointChart: View {
    let dataPoints: [(x: CGFloat, y: CGFloat)]
    let showAxisLabels: Bool
    let axisColor: Color
    
    public init(dataPoints: [(x: CGFloat, y: CGFloat)], showAxisLabels: Bool = true, axisColor: Color = .gray) {
        self.dataPoints = dataPoints
        self.showAxisLabels = showAxisLabels
        self.axisColor = axisColor
    }

    public var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // Normalize the data to fit within the chart area
                    let xMin = dataPoints.map(\.x).min()!
                    let xMax = dataPoints.map(\.x).max()!
                    let yMin = dataPoints.map(\.y).min()!
                    let yMax = dataPoints.map(\.y).max()!
                    
                    let xRange = max(xMax - xMin, 0.001) // Avoid division by zero
                    let yRange = max(yMax - yMin, 0.001) // Avoid division by zero
                    
                    Path { path in
                        // Move to the starting point
                        let startX = (dataPoints[0].x - xMin) / xRange * geometry.size.width
                        let startY = geometry.size.height - (dataPoints[0].y - yMin) / yRange * geometry.size.height
                        path.move(to: CGPoint(x: startX, y: startY))
                        
                        for point in dataPoints {
                            // Normalize x and y based on the data range
                            let normalizedX = (point.x - xMin) / xRange
                            let normalizedY = (point.y - yMin) / yRange
                            
                            // Convert normalized values to screen coordinates
                            let x = normalizedX * geometry.size.width
                            let y = geometry.size.height - (normalizedY * geometry.size.height)
                            
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))

                    ForEach(dataPoints, id: \.x) { point in
                        // Normalize and position the circles
                        let normalizedX = (point.x - xMin) / xRange
                        let normalizedY = (point.y - yMin) / yRange

                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .position(x: normalizedX * geometry.size.width,
                                      y: geometry.size.height - (normalizedY * geometry.size.height))
                    }

                    // X-Axis
                    Path { path in
                        // Position at actual y = 0
                        let yZero = geometry.size.height - (-yMin / yRange * geometry.size.height)
                        path.move(to: CGPoint(x: 0, y: yZero))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: yZero))
                    }
                    .stroke(axisColor, style: StrokeStyle(lineWidth: 1)) // Customize axis color

                    // Y-Axis
                    Path { path in
                        // Position at actual x = 0
                        let xZero = (-xMin / xRange) * geometry.size.width
                        path.move(to: CGPoint(x: xZero, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: xZero, y: 0))
                    }
                    .stroke(axisColor, style: StrokeStyle(lineWidth: 1)) // Customize axis color

                    if showAxisLabels {
                        // Origin Label (optional) - now positioned at actual (0, 0)
                        Text("(0, 0)")
                            .font(.caption)
                            .position(x: (-xMin / xRange) * geometry.size.width + 10,
                                      y: geometry.size.height - (-yMin / yRange * geometry.size.height) - 10) // Adjust position
                    }
                }
                .padding()
            }
        }
}
