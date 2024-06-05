import SwiftUI

/// Defines types that can be converted to plottable numerical values for use in charts.
///
/// Any type conforming to this protocol must provide a method to represent its value as a `Double`, making it usable for quantitative analysis and visualization.
public protocol Plottable: Equatable, Hashable {

    /// Converts the instance's value to a `Double` representation.
    func toDouble() -> Double
}


@available(iOS 13.0, *)
/// Represents a visual axis in a chart, used to define scales and label formatting.
///
/// The axis provides a mapping function (`scale`) to transform plottable values into screen coordinates and a formatter function (`labelFormatter`) to generate readable labels.
public protocol Axis: View {
    
    /// The type of plottable values used for this axis.
    associatedtype T: Plottable

    /// A function that maps plottable values (`T`) to coordinates along the axis.
    var scale: (T) -> CGFloat { get }

    /// A function that formats plottable values (`T`) into strings for axis labels.
    var labelFormatter: (T) -> String { get }

    // ... (Potential additional properties for label styling, tick marks, etc.)
}

@available(iOS 15.0, *)
/// A visual element used to represent individual data points or groups of data points within a chart.
///
/// Marks are responsible for rendering data points according to their type (e.g., bars, lines, points) and provide customizable styling and interactive behaviors.
public protocol Mark: View {

    /// The type of data point this mark represents.
    associatedtype T: DataPoint

    /// Draws the mark using the provided data points, graphics context, and size.
    func draw(data: [T], context: inout GraphicsContext, size: CGSize)

    // ... (Properties for styling, animation, interactions, etc.)
}


@available(iOS 13.0, *)
/// A protocol for types that modify the appearance or behavior of a chart.
///
/// Chart modifiers are applied to a base chart type and return a modified version. This allows for composable customization of charts.
public protocol ChartModifier {

    /// The type of chart this modifier can be applied to.
    associatedtype Body: Chart

    /// Applies the modifier to the content and returns the modified chart.
    func body(content: Body) -> Body
}


@available(iOS 13.0, *)
/// A visual representation of data, composed of axes, marks, and data points.
///
/// Charts are the main building blocks for data visualization and analysis. They provide a structured way to display and interact with data.
public protocol Chart: View {

    /// The type of data point used in this chart.
    associatedtype T: DataPoint

    /// The array of data points to be visualized in the chart.
    var data: [T] { get }
}


@available(iOS 13.0, *)
/// Defines the structure of individual data points for use in charts.
///
/// Data points typically contain at least two plottable values (`x` and `y`) and can include additional metadata for styling or interactions.
public protocol DataPoint: Identifiable, Hashable, Comparable {

    /// The type of plottable value used for the x-axis.
    associatedtype T: Plottable

    /// The type of plottable value used for the y-axis.
    associatedtype U: Plottable

    /// A unique identifier for the data point.
    var id: UUID { get }

    /// The x-value of the data point.
    var x: T { get }

    /// The y-value of the data point.
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
/// A SwiftUI view that displays a line chart based on an array of `DataPoint` values.
///
/// This chart renders data points as a connected line, with axes for context.
///
/// - Example:
///
/// ```swift
/// struct MyDataPoint: DataPoint {
///     var id = UUID()
///     var x: Int
///     var y: Double
/// }
///
/// let sampleData: [MyDataPoint] = [
///     MyDataPoint(x: 1, y: 3.2),
///     MyDataPoint(x: 2, y: 5.8),
///     // ... more data points
/// ]
///
/// LineChart(data: sampleData) // Creates and displays the line chart.
/// ```
public struct LineChart<T: DataPoint>: Chart {
    public var data: [T]
    
    public init(data: [T]) {
        self.data = data
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let normalizedData = normalizeData(for: geometry.size)
            Path { path in
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
                
                let maxY = data.map { $0.y.toDouble() }.max()!
                
                let minY = data.map { $0.y.toDouble() }.min()!
                
                let baselineY = minY < 0 ? (maxY/(maxY-minY))*geometry.size.height : geometry.size.height
                
                path.move(to: CGPoint(x: 0, y: baselineY))
                path.addLine(to: CGPoint(x: geometry.size.width, y: baselineY)) // X-axis
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: geometry.size.height)) // Y-axis
            }
            .stroke(Color.gray)
        }
    }
}

@available(iOS 15.0, *)
/// A SwiftUI view that displays a bar chart based on an array of `DataPoint` values.
///
/// This chart renders data points as vertical bars, with the height of each bar representing the corresponding y-value. Bars can be positive (blue) or negative (red).
///
/// - Example:
///
/// ```swift
/// struct MyDataPoint: DataPoint {
///     var id = UUID()
///     var x: String // Category labels (e.g., "Jan", "Feb", ...)
///     var y: Double // Value of each category
/// }
///
/// let sampleData: [MyDataPoint] = [
///     MyDataPoint(x: "Jan", y: 150),
///     MyDataPoint(x: "Feb", y: -80), // Negative value
///     // ... more data points
/// ]
///
/// BarChart(data: sampleData, barSpacing: 15) // Creates the bar chart with custom spacing
/// ```
public struct BarChart<T: DataPoint>: Chart {
    
    public var data: [T]
    var barSpacing: CGFloat = 10

    public init(data: [T], barSpacing: CGFloat = 10) {
        self.data = data
        self.barSpacing = barSpacing
    }

    public var body: some View {
        GeometryReader { geometry in
            let normalizedYValues = normalizeData(for: geometry.size)
            ZStack {
                // Move the HStack inside a VStack to control padding
                VStack(spacing: 0) { // No spacing to avoid offsetting the x-axis
                    HStack(spacing: barSpacing) {
                        ForEach(data.indices, id: \.self) { index in
                            VStack(alignment: .center) {
                                let normalizedY = normalizedYValues[index].y
                                
                                Rectangle()
                                    .fill(normalizedY >= 0 ? Color.blue : Color.red)
                                    .frame(height: abs(normalizedY))
                                    .offset(y: -normalizedY / 2) // Center bars
                                
                            }
                        }
                    }
                    .padding(.horizontal) // Apply padding to the HStack only
                }

                // Draw axes at the center (no changes here)
                Path { path in
                    // Calculate the y-coordinate for the x-axis baseline
                    let baselineY = geometry.size.height / 2
                    
                    // X-axis (at the calculated baseline)
                    path.move(to: CGPoint(x: 0, y: baselineY))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: baselineY))
                    
                    // Y-axis (no changes)
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                }
                .stroke(Color.gray)
            }
        }
    }
    func normalizeData(for size: CGSize) -> [CGPoint] {
        guard !data.isEmpty else { return [] }
        
        let minX = data.map({ $0.x.toDouble() }).min()!
        let maxX = data.map({ $0.x.toDouble() }).max()!
        
        let minY = data.map({ $0.y.toDouble() }).min()!
        let maxY = data.map({ $0.y.toDouble() }).max()!

        let xScale = size.width / (maxX - minX)
        let yScale = size.height / (2 * max(abs(minY), abs(maxY))) // Scale factor to fit in the view's height
        let absMaxY = max(abs(minY), abs(maxY)) // Maximum absolute value of y

        return data.map { point in
            let normalizedX = CGFloat((point.x.toDouble() - minX) * xScale)
            let normalizedY = CGFloat((point.y.toDouble() / absMaxY) * yScale) // Normalize y-value by absolute maxY
            return CGPoint(x: normalizedX, y: normalizedY)
        }
    }
}
