import SwiftUI

@available(iOS 13.0, *)
public struct PointChart: View {
    /// The data points to be plotted on the chart.
    let dataPoints: [(x: CGFloat, y: CGFloat)]

    /// Customization options for the chart's appearance.
    var chartStyle: ChartStyle
    
    /// Initializes a PointChart.
    /// - Parameters:
    ///   - dataPoints: The data points to plot.
    ///   - chartStyle: Customization options for the chart's appearance.
    public init(dataPoints: [(x: CGFloat, y: CGFloat)], chartStyle: ChartStyle = ChartStyle()) {
        self.dataPoints = dataPoints
        self.chartStyle = chartStyle
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ChartContent(dataPoints: dataPoints, geometry: geometry)
                    .stroke(chartStyle.lineColor, style: chartStyle.lineStyle)

                PointsOverlay(dataPoints: dataPoints, geometry: geometry, fillColor: Color.red)

                ChartAxes(
                    dataPoints: dataPoints,
                    geometry: geometry,
                    chartStyle: chartStyle
                )
            }
            .padding()
        }
    }
}

/// Customization options for the chart's appearance.
@available(iOS 13.0, *)
public struct ChartStyle {
    /// The color of the line connecting data points.
    public var lineColor: Color

    /// The style of the line connecting data points.
    public var lineStyle: StrokeStyle

    /// The color of the data point markers.
    public var pointColor: Color

    /// Whether to display axis labels.
    public var showAxisLabels: Bool

    /// The color of the chart's axes.
    public var axisColor: Color
    

    /// Initializes a ChartStyle with default values.
    public init(
        lineColor: Color = .blue,
        lineStyle: StrokeStyle = StrokeStyle(lineWidth: 2, lineCap: .round),
        pointColor: Color = .red,
        showAxisLabels: Bool = true,
        axisColor: Color = .gray
    ) {
        self.lineColor = lineColor
        self.lineStyle = lineStyle
        self.pointColor = pointColor
        self.showAxisLabels = showAxisLabels
        self.axisColor = axisColor
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
    var chartStyle: ChartStyle

    var body: some View {
        let (xMin, xMax, yMin, yMax) = normalizeData(dataPoints)

        ZStack {
            // X-Axis
            Path { path in
                let yZero = yPosition(for: 0, yMin: yMin, yMax: yMax, height: geometry.size.height)
                path.move(to: CGPoint(x: 0, y: yZero))
                path.addLine(to: CGPoint(x: geometry.size.width, y: yZero))
            }
            .stroke(chartStyle.axisColor, style: StrokeStyle(lineWidth: 1))

            // Y-Axis
            Path { path in
                let xZero = xPosition(for: 0, xMin: xMin, xMax: xMax, width: geometry.size.width)
                path.move(to: CGPoint(x: xZero, y: geometry.size.height))
                path.addLine(to: CGPoint(x: xZero, y: 0))
            }
            .stroke(chartStyle.axisColor, style: StrokeStyle(lineWidth: 1))

            if chartStyle.showAxisLabels {
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
