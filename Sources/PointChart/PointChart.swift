import SwiftUI

public struct PointChart: View {
    let dataPoints: [(x: CGFloat, y: CGFloat)]

    public init(dataPoints: [(x: CGFloat, y: CGFloat)]) {
        self.dataPoints = dataPoints
    }

    @available(iOS 13.0.0, *)
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Normalize the data to fit within the chart area
                let xRange = dataPoints.map(\.x).max()! - dataPoints.map(\.x).min()!
                let yRange = dataPoints.map(\.y).max()! - dataPoints.map(\.y).min()!
                
                Path { path in
                    // Move to the starting point
                    let startX = (dataPoints[0].x - dataPoints.map(\.x).min()!) / xRange * geometry.size.width
                    let startY = geometry.size.height - (dataPoints[0].y - dataPoints.map(\.y).min()!) / yRange * geometry.size.height
                    path.move(to: CGPoint(x: startX, y: startY))
                    
                    for point in dataPoints {
                        // Normalize x and y based on the data range
                        let normalizedX = (point.x - dataPoints.map(\.x).min()!) / xRange
                        let normalizedY = (point.y - dataPoints.map(\.y).min()!) / yRange
                        
                        // Convert normalized values to screen coordinates
                        let x = normalizedX * geometry.size.width
                        let y = geometry.size.height - (normalizedY * geometry.size.height)
                        
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))

                ForEach(dataPoints, id: \.x) { point in
                    // Normalize and position the circles
                    let normalizedX = (point.x - dataPoints.map(\.x).min()!) / xRange
                    let normalizedY = (point.y - dataPoints.map(\.y).min()!) / yRange

                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .position(x: normalizedX * geometry.size.width,
                                  y: geometry.size.height - (normalizedY * geometry.size.height))
                }
            }
            .padding() // Add padding around the chart
        }
    }
}
