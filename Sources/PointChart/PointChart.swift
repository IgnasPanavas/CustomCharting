import SwiftUI

// PlottableValue Protocol: Defines types that can be converted to plottable values.
public protocol Plottable {
    func toDouble() -> Double
}

// Chart Protocol (Updated)
@available(iOS 13.0, *)
public protocol Chart: View {
    associatedtype T: DataPoint
    var data: [T] { get }
}
// DataPoint Protocol: Defines the structure of data points for any chart.
public protocol DataPoint: Plottable {
    associatedtype T: Plottable
    associatedtype U: Plottable
    
    var x: T { get } // Assumes numeric X-axis for now.
    var y: U { get }
}

// Default Implementation in Chart Protocol
@available(iOS 13.0, *)
public extension Chart {
    func normalizeData(for size: CGSize) -> [CGPoint] {
        guard !data.isEmpty else { return [] }

        let minX = data.map { $0.x.toDouble() }.min()!
        let maxX = data.map { $0.x.toDouble() }.max()!
        let minY = data.map { $0.y.toDouble() }.min()!
        let maxY = data.map { $0.y.toDouble() }.max()!

        let xScale = size.width / (maxX - minX)
        let yScale = size.height / (maxY - minY)

        return data.map { point in
            let normalizedX = (point.x.toDouble() - minX) * xScale
            let normalizedY = size.height - (point.y.toDouble() - minY) * yScale // Invert Y-axis
            return CGPoint(x: normalizedX, y: normalizedY)
        }
    }
}


@available(iOS 13.0, *)
public struct LineChart<T: DataPoint>: Chart {
    public var data: [T]
    
    public init(data: [T]) {
        self.data = data
    }
    
    public var body: some View {
        GeometryReader { geometry in
            Path { path in
                let normalizedData = normalizeData(for: geometry.size)
                for (index, point) in normalizedData.enumerated() {
                    if index == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
            }
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            
            // Draw axes (you can customize styling)
            Path { path in
                path.move(to: CGPoint(x: 0, y: geometry.size.height))
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height)) // X-axis
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: geometry.size.height)) // Y-axis
            }
            .stroke(Color.gray)
        }
    }
}

@available(iOS 15.0, *)
public struct BarChart<T: DataPoint>: Chart {
    public var data: [T]
    var barSpacing: CGFloat = 10

    public init(data: [T], barSpacing: CGFloat = 10) {
        self.data = data
        self.barSpacing = barSpacing
    }

    
    public var body: some View {
        GeometryReader { geometry in
            HStack(spacing: barSpacing) {
                ForEach(data.indices, id: \.self) { index in
                    VStack(alignment: .center) { // Center-align text within VStack
                        // Calculate bar height using the generalized normalizeData method
                        let barHeight = normalizeData(for: geometry.size)[index].y
                        Spacer() // Push the rectangle to the bottom
                        Rectangle()
                            .fill(Color.blue)
                            .frame(height: abs(barHeight)) // Use absolute value for height
                            .offset(y: -barHeight / 2)   // Offset to center bar vertically
                        Text(data[index].x.toDouble(), format: .number)
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
