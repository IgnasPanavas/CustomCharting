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

@available(iOS 13.0, *)
public struct PointChart1: View {
    /// The data points to be plotted on the chart.
    let dataPoints: [(x: CGFloat, y: CGFloat)]

    /// Whether to display axis labels (default: true).
    let showAxisLabels: Bool

    /// The color of the axes (default: gray).
    let axisColor: Color
    

    /// Initializes a PointChart.
    /// - Parameters:
    ///   - dataPoints: The data points to plot.
    ///   - showAxisLabels: Whether to display axis labels.
    ///   - axisColor: The color of the axes.
    public init(dataPoints: [(x: CGFloat, y: CGFloat)], showAxisLabels: Bool = true, axisColor: Color = .gray) {
        self.dataPoints = dataPoints
        self.showAxisLabels = showAxisLabels
        self.axisColor = axisColor
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ChartContent(dataPoints: dataPoints, geometry: geometry)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))

                PointsOverlay(dataPoints: dataPoints, geometry: geometry, fillColor: Color.red)

                ChartAxes(
                    dataPoints: dataPoints,
                    geometry: geometry,
                    showAxisLabels: showAxisLabels,
                    axisColor: axisColor
                )
            }
            .padding()
        }
    }
}

/// The main chart content, drawing the line connecting the data points.
@available(iOS 13.0, *)
private struct ChartContent: Shape {
    let dataPoints: [(x: CGFloat, y: CGFloat)]
    let geometry: GeometryProxy

    func path(in rect: CGRect) -> Path {
        let (xMin, xMax, yMin, yMax) = normalizeData(dataPoints)

        var path = Path()

        let startX = xPosition(for: dataPoints[0].x, xMin: xMin, xMax: xMax, width: geometry.size.width)
        let startY = yPosition(for: dataPoints[0].y, yMin: yMin, yMax: yMax, height: geometry.size.height)
        path.move(to: CGPoint(x: startX, y: startY))

        for point in dataPoints {
            let x = xPosition(for: point.x, xMin: xMin, xMax: xMax, width: geometry.size.width)
            let y = yPosition(for: point.y, yMin: yMin, yMax: yMax, height: geometry.size.height)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}


/// The overlay of circles representing individual data points.
@available(iOS 13.0, *)
private struct PointsOverlay: View {
    let dataPoints: [(x: CGFloat, y: CGFloat)]
    let geometry: GeometryProxy
    var fillColor: Color
    
    var body: some View {
        let (xMin, xMax, yMin, yMax) = normalizeData(dataPoints)

        ForEach(dataPoints, id: \.x) { point in
            Circle()
                .fill(fillColor)
                .frame(width: 8, height: 8)
                .position(
                    x: xPosition(for: point.x, xMin: xMin, xMax: xMax, width: geometry.size.width),
                    y: yPosition(for: point.y, yMin: yMin, yMax: yMax, height: geometry.size.height)
                )
        }
    }
}


/// The X and Y axes for the chart.
@available(iOS 13.0, *)
private struct ChartAxes: View {
    let dataPoints: [(x: CGFloat, y: CGFloat)]
    let geometry: GeometryProxy
    let showAxisLabels: Bool
    let axisColor: Color

    var body: some View {
        let (xMin, xMax, yMin, yMax) = normalizeData(dataPoints)

        ZStack {
            // X-Axis
            Path { path in
                let yZero = yPosition(for: 0, yMin: yMin, yMax: yMax, height: geometry.size.height)
                path.move(to: CGPoint(x: 0, y: yZero))
                path.addLine(to: CGPoint(x: geometry.size.width, y: yZero))
            }
            .stroke(axisColor, style: StrokeStyle(lineWidth: 1))

            // Y-Axis
            Path { path in
                let xZero = xPosition(for: 0, xMin: xMin, xMax: xMax, width: geometry.size.width)
                path.move(to: CGPoint(x: xZero, y: geometry.size.height))
                path.addLine(to: CGPoint(x: xZero, y: 0))
            }
            .stroke(axisColor, style: StrokeStyle(lineWidth: 1))

            if showAxisLabels {
                Text("(0, 0)")
                    .font(.caption)
                    .position(
                        x: xPosition(for: 0, xMin: xMin, xMax: xMax, width: geometry.size.width) + 10,
                        y: yPosition(for: 0, yMin: yMin, yMax: yMax, height: geometry.size.height) - 10
                    )
            }
        }
    }
}


// Helper functions to normalize data and calculate positions within the chart area.

/// Normalizes the data points to fit within a 0 to 1 range.
/// - Parameter dataPoints: The data points to normalize.
/// - Returns: A tuple containing the normalized minimum and maximum x and y values.
@available(iOS 13.0, *)
private func normalizeData(_ dataPoints: [(x: CGFloat, y: CGFloat)]) -> (xMin: CGFloat, xMax: CGFloat, yMin: CGFloat, yMax: CGFloat) {
    let xMin = dataPoints.map(\.x).min()!
    let xMax = dataPoints.map(\.x).max()!
    let yMin = dataPoints.map(\.y).min()!
    let yMax = dataPoints.map(\.y).max()!
    let xRange = max(xMax - xMin, 0.001) // Avoid division by zero
    let yRange = max(yMax - yMin, 0.001) // Avoid division by zero
    return (xMin, xMax, yMin, yMax)
}


/// Calculates the x position for a given value based on the chart dimensions and data range.
/// - Parameters:
///   - value: The x value to calculate the position for.
///   - xMin: The minimum x value in the data.
///   - xMax: The maximum x value in the data.
///   - width: The width of the chart area.
/// - Returns: The x position within the chart area.
@available(iOS 13.0, *)
private func xPosition(for value: CGFloat, xMin: CGFloat, xMax: CGFloat, width: CGFloat) -> CGFloat {
    let normalizedX = (value - xMin) / max(xMax - xMin, 0.001) // Avoid division by zero
    return normalizedX * width
}


/// Calculates the y position for a given value based on the chart dimensions and data range.
/// - Parameters:
///   - value: The y value to calculate the position for.
///   - yMin: The minimum y value in the data.
///   - yMax: The maximum y value in the data.
///   - height: The height of the chart area.
/// - Returns: The y position within the chart area.
@available(iOS 13.0, *)
private func yPosition(for value: CGFloat, yMin: CGFloat, yMax: CGFloat, height: CGFloat) -> CGFloat {
    let normalizedY = (value - yMin) / max(yMax - yMin, 0.001) // Avoid division by zero
    return height - (normalizedY * height)
}
