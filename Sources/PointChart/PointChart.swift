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
            ZStack { // Use ZStack to overlay bars and axes
                HStack(spacing: barSpacing) {
                    ForEach(data.indices, id: \.self) { index in
                        VStack(alignment: .center) {
                            let barHeight = normalizeData(for: geometry.size)[index].y
                            Spacer()
                            Rectangle()
                                .fill(barHeight >= 0 ? Color.blue : Color.red) // Color based on sign
                                .frame(height: abs(barHeight))
                            Text(data[index].x.toDouble(), format: .number)
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal)

                // Draw axes
                Path { path in
                    // X-axis (at the baseline for the bars)
                    path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
                    
                    // Y-axis
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                }
                .stroke(Color.gray)
            }
        }
    }

    private func normalizeData(for size: CGSize) -> [CGPoint] {
        guard !data.isEmpty else { return [] }

        let minY = data.map { $0.y.toDouble() }.min()!
        let maxY = data.map { $0.y.toDouble() }.max()!

        // Scale factor for positive and negative values separately
        let positiveYScale = size.height / 2 / max(maxY, 0) // Only scale by positive maximum
        let negativeYScale = size.height / 2 / abs(min(minY, 0)) // Only scale by negative minimum

        return data.map { point in
            let barHeight = point.y.toDouble() >= 0
                ? point.y.toDouble() * positiveYScale
                : point.y.toDouble() * negativeYScale
            return CGPoint(x: 0, y: barHeight)  // Y value is now the offset from the baseline
        }
    }
}
