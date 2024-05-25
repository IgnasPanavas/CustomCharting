import SwiftUI

public struct PointChart: View {
    let dataPoints: [(x: CGFloat, y: CGFloat)] // Array of (x, y) data
    
    public init(dataPoints: [(x: CGFloat, y: CGFloat)]) {
        self.dataPoints = dataPoints
    }
    
    @available(iOS 13.0.0, *)
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path { path in // Draw the connecting lines
                    path.move(to: CGPoint(x: 0, y: geometry.size.height))
                    for point in dataPoints {
                        let x = point.x * geometry.size.width
                        let y = geometry.size.height - (point.y * geometry.size.height)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                
                ForEach(dataPoints, id: \.x) { point in // Plot the points
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .position(x: point.x * geometry.size.width,
                                  y: geometry.size.height - (point.y * geometry.size.height))
                }
            }
            .padding()
        }
    }
}
