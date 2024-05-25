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
                
                let xRange = max(abs(xMin), xMax) * 2 // Double the range for negative values
                let yRange = max(abs(yMin), yMax) * 2
                
                Path { path in
                    // Move to the starting point (adjust for negative x/y)
                    let startX = ((dataPoints[0].x - xMin) / xRange) * geometry.size.width
                    let startY = geometry.size.height - ((dataPoints[0].y - yMin) / yRange) * geometry.size.height
                    path.move(to: CGPoint(x: startX, y: startY))
                    
                    for point in dataPoints {
                        // Normalize x and y based on the data range (with negative values)
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
                    // Normalize and position the circles (with negative values)
                    let normalizedX = (point.x - xMin) / xRange
                    let normalizedY = (point.y - yMin) / yRange
                    
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .position(x: normalizedX * geometry.size.width,
                                  y: geometry.size.height - (normalizedY * geometry.size.height))
                }
                
                // X-Axis (centered vertically)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
                }
                .stroke(axisColor, style: StrokeStyle(lineWidth: 1))
                
                // Y-Axis (centered horizontally)
                Path { path in
                    path.move(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: geometry.size.width / 2, y: 0))
                }
                .stroke(axisColor, style: StrokeStyle(lineWidth: 1))
                
                if showAxisLabels {
                    // Origin Label (optional)
                    Text("(0, 0)")
                        .font(.caption)
                        .position(x: geometry.size.width / 2 + 10, y: geometry.size.height / 2 - 10) // Adjust position
                }
            }
            .padding()
        }
    }
}
