import SwiftUI

public protocol Plottable {
    associatedtype Value: Comparable
    var value: Value { get }
    func toCGFloat() -> CGFloat
}


// Chart Protocol
@available(iOS 13.0, *)
public protocol Chart {
    associatedtype XValue: Plottable & Hashable
    associatedtype YValue: Plottable & Hashable
    associatedtype ContentView: View // Associated type for the content view
    
    var dataPoints: [DataPoint<XValue, YValue>] { get }
    var showAxisLabels: Bool { get }
    var axisColor: Color { get }
    
    func normalizeData() -> (xMin: CGFloat, xMax: CGFloat, yMin: CGFloat, yMax: CGFloat)
    func plotContent(in geometry: GeometryProxy) -> ContentView // Use the associated type
}

public struct DataPoint<X: Plottable, Y: Plottable>: Identifiable, Hashable where X: Hashable, Y: Hashable {
    public let id = UUID()
    public let x: X
    public let y: Y

    var dataPoint: (CGFloat, CGFloat) { (x.toCGFloat(), y.toCGFloat()) }
    
    public init(x: X, y: Y) {
        self.x = x
        self.y = y
    }
    // Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Use the unique id for hashing
        hasher.combine(x) // Hash the x value
        hasher.combine(y) // Hash the y value
    }
}

// MARK: - LineChart (Struct)

@available(iOS 13.0, *)
public struct LineChart<XValue: Plottable & Hashable, YValue: Plottable & Hashable>: Chart, View {
    // LineChart composes BaseChart
    var baseChart: BaseChart<XValue, YValue>

    public var dataPoints: [DataPoint<XValue, YValue>] { baseChart.dataPoints }
    public var showAxisLabels: Bool {
        get { baseChart.showAxisLabels }
        set { baseChart.showAxisLabels = newValue }
    }
    public var axisColor: Color {
        get { baseChart.axisColor }
        set { baseChart.axisColor = newValue }
    }
    public typealias ContentView = ChartContent
    
    public init(dataPoints: [DataPoint<XValue, YValue>]) {
        self.baseChart = BaseChart(dataPoints: dataPoints)
    }

    // LineChart-specific plotContent implementation
    public func plotContent(in geometry: GeometryProxy) -> ChartContent {
        ChartContent(dataPoints: dataPoints.map(\.dataPoint), geometry: geometry)
    }

    // Inherit other properties and methods directly from BaseChart using baseChart
    public func normalizeData() -> (xMin: CGFloat, xMax: CGFloat, yMin: CGFloat, yMax: CGFloat) {
        return baseChart.normalizeData()
    }

    public func chartAxes(in geometry: GeometryProxy) -> some View {
        return baseChart.chartAxes(in: geometry)
    }
    
    public var body: some View {
        baseChart.body
    }
}


@available(iOS 13.0, *)
public struct BaseChart<XValue: Plottable & Hashable, YValue: Plottable & Hashable>: Chart {
    public let dataPoints: [DataPoint<XValue, YValue>]
    public var showAxisLabels = true
    public var axisColor = Color.gray
    // Stylistic properties
    @Environment(\.lineColor) var lineColor: Color
    @Environment(\.pointColor) var pointColor: Color
    @Environment(\.lineStyle) var lineStyle: StrokeStyle
    @Environment(\.showPoints) var showPoints: Bool

    public init(dataPoints: [DataPoint<XValue, YValue>]) {
        self.dataPoints = dataPoints
    }
    
    public typealias ContentView = ChartContent // Declare the associated type
        // Implementation for normalizeData
        public func normalizeData() -> (xMin: CGFloat, xMax: CGFloat, yMin: CGFloat, yMax: CGFloat) {
            let xValues = dataPoints.map { $0.x.toCGFloat() }
            let yValues = dataPoints.map { $0.y.toCGFloat() }
            
            let xMin = xValues.min() ?? 0
            let xMax = xValues.max() ?? 0
            let yMin = yValues.min() ?? 0
            let yMax = yValues.max() ?? 0

            return (xMin, xMax, yMin, yMax)
        }
        
        // Axes View (common to all chart types)
        public func chartAxes(in geometry: GeometryProxy) -> some View {
            ChartAxes(dataPoints: dataPoints.map(\.dataPoint), geometry: geometry, axisColor: axisColor, showAxisLabels: showAxisLabels)
        }

    // Plotting Logic (To be customized per chart type)
        public func plotContent(in geometry: GeometryProxy) -> ChartContent {
            fatalError("plotContent() must be implemented by the specific chart type.")
        }
        
        public var body: some View {
            GeometryReader { geometry in
                ZStack {
                    plotContent(in: geometry)
                        .stroke(lineColor, style: lineStyle)
                    if showPoints {
                        PointsOverlay(dataPoints: dataPoints, geometry: geometry, pointColor: pointColor)
                    }
                    chartAxes(in: geometry)
                }
                .padding()
            }
        }
    }

/// The main chart content, drawing the line connecting the data points.
@available(iOS 13.0, *)
public struct ChartContent: Shape {
    let dataPoints: [(CGFloat, CGFloat)]
    let geometry: GeometryProxy

    public func path(in rect: CGRect) -> Path {
        let (xMin, xMax, yMin, yMax) = normalizeData(dataPoints)

        var path = Path()

        let startX = xPosition(for: dataPoints[0].0, xMin: xMin, xMax: xMax, width: geometry.size.width)
        let startY = yPosition(for: dataPoints[0].1, yMin: yMin, yMax: yMax, height: geometry.size.height)
        path.move(to: CGPoint(x: startX, y: startY))

        for point in dataPoints {
            let x = xPosition(for: point.0, xMin: xMin, xMax: xMax, width: geometry.size.width)
            let y = yPosition(for: point.1, yMin: yMin, yMax: yMax, height: geometry.size.height)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

/// The overlay of circles representing individual data points.
@available(iOS 13.0, *)
private struct PointsOverlay<X: Plottable & Hashable, Y: Plottable & Hashable>: View {
    let dataPoints: [DataPoint<X, Y>]
    let geometry: GeometryProxy
    var pointColor: Color

    var body: some View {
        let (xMin, xMax, yMin, yMax) = normalizeData(dataPoints.map(\.dataPoint))

        ForEach(dataPoints) { point in
            Circle()
                .fill(pointColor)
                .frame(width: 8, height: 8)
                .position(
                    // Directly access the pre-calculated CGFloats
                    x: xPosition(for: point.dataPoint.0, xMin: xMin, xMax: xMax, width: geometry.size.width),
                    y: yPosition(for: point.dataPoint.1, yMin: yMin, yMax: yMax, height: geometry.size.height)
                )
        }
    }
}


// Chart Axes
@available(iOS 13.0, *)
private struct ChartAxes: View {
    let dataPoints: [(CGFloat, CGFloat)]
    let geometry: GeometryProxy
    
    var axisColor: Color
    var showAxisLabels: Bool

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

/// Normalizes data points to fit within a 0 to 1 range for plotting on a chart.
///
/// - Parameter dataPoints: An array of tuples representing data points. Each tuple is in the format `(x: CGFloat, y: CGFloat)`.
/// - Returns: A tuple containing the normalized minimum and maximum x and y values: `(xMin: CGFloat, xMax: CGFloat, yMin: CGFloat, yMax: CGFloat)`.
@available(iOS 13.0, *)
private func normalizeData(_ dataPoints: [(CGFloat, CGFloat)]) -> (xMin: CGFloat, xMax: CGFloat, yMin: CGFloat, yMax: CGFloat) {
    let xValues = dataPoints.map { $0.0 }
    let yValues = dataPoints.map { $0.1 }

    let xMin = xValues.min()!
    let xMax = xValues.max()!
    let yMin = yValues.min()!
    let yMax = yValues.max()!

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


// MARK: - Modifier Structs
@available(iOS 13.0, *)
private struct LineColorModifier: ViewModifier {
    let color: Color
    func body(content: Content) -> some View {
        content.environment(\.lineColor, color)
    }
}

@available(iOS 13.0, *)
private struct LineStyleModifier: ViewModifier {
    let style: StrokeStyle
    func body(content: Content) -> some View {
        content.environment(\.lineStyle, style)
    }
}

@available(iOS 13.0, *)
private struct PointColorModifier: ViewModifier {
    let color: Color
    func body(content: Content) -> some View {
        content.environment(\.pointColor, color)
    }
}

@available(iOS 13.0, *)
private struct ShowAxisLabelsModifier: ViewModifier {
    let show: Bool
    func body(content: Content) -> some View {
        content.environment(\.showAxisLabels, show)
    }
}

@available(iOS 13.0, *)
private struct ShowPointsModifier: ViewModifier {
    let show: Bool
    func body(content: Content) -> some View {
        content.environment(\.showPoints, show)
    }
}

@available(iOS 13.0, *)
private struct AxisColorModifier: ViewModifier {
    let color: Color
    func body(content: Content) -> some View {
        content.environment(\.axisColor, color)
    }
}

// MARK: - Environment Keys
@available(iOS 13.0, *)
private struct PointColorKey: EnvironmentKey {
    static let defaultValue = Color.red
}

@available(iOS 13.0, *)
private struct LineStyleKey: EnvironmentKey {
    static let defaultValue = StrokeStyle(lineWidth: 2)
}

@available(iOS 13.0, *)
private struct LineColorKey: EnvironmentKey {
    static let defaultValue = Color.red
}

@available(iOS 13.0, *)
private struct ShowAxisLabelsKey: EnvironmentKey {
    static let defaultValue = true
}

@available(iOS 13.0, *)
private struct ShowPointsKey: EnvironmentKey {
    static let defaultValue = true
}

@available(iOS 13.0, *)
private struct AxisColorKey: EnvironmentKey {
    static let defaultValue = Color.gray
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    var pointColor: Color {
        get { self[PointColorKey.self] }
        set { self[PointColorKey.self] = newValue }
    }

    var showAxisLabels: Bool {
        get { self[ShowAxisLabelsKey.self] }
        set { self[ShowAxisLabelsKey.self] = newValue }
    }

    var axisColor: Color {
        get { self[AxisColorKey.self] }
        set { self[AxisColorKey.self] = newValue }
    }
    var lineStyle: StrokeStyle {
        get { self[LineStyleKey.self] }
        set { self[LineStyleKey.self] = newValue }
    }
    var lineColor: Color {
        get { self[LineColorKey.self] }
        set { self[LineColorKey.self] = newValue }
    }
    var showPoints: Bool {
        get { self[ShowPointsKey.self] }
        set { self[ShowPointsKey.self] = newValue }
    }
}

// MARK: - Modifiers for Styling
@available(iOS 13.0, *)
extension View {
    public func lineColor(_ color: Color) -> some View {
        self.modifier(LineColorModifier(color: color))
    }

    public func lineStyle(_ style: StrokeStyle) -> some View {
        self.modifier(LineStyleModifier(style: style))
    }

    public func pointColor(_ color: Color) -> some View {
        self.modifier(PointColorModifier(color: color))
    }

    public func showAxisLabels(_ show: Bool) -> some View {
        self.modifier(ShowAxisLabelsModifier(show: show))
    }
    
    public func showPoints(_ show: Bool) -> some View {
        self.modifier(ShowPointsModifier(show: show))
    }

    public func axisColor(_ color: Color) -> some View {
        self.modifier(AxisColorModifier(color: color))
    }
}
