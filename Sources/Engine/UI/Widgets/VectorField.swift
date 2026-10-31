import Foundation

/// A row of 2, 3 or 4 `NumberField`s for a vector, each with a colored axis label (X red, Y
/// green, Z blue, W gray) and an equal share of the width.
///
/// The edit callbacks describe one gesture on the whole vector, with the same phases as
/// `NumberField`: `onEditBegan(start)` when any component starts changing (the vector before),
/// `onChange(values)` after every change, `onEditEnded(start, end)` when that component's
/// gesture ends. Component gestures never overlap, so an undo system sees one step per scrub or
/// typed value. `setValues` (no callbacks) is ignored while a component is being edited.
public final class VectorField: Stack {
    public static let axisNames = ["X", "Y", "Z", "W"]
    /// X red, Y green, Z blue, W gray.
    /// The dark theme's `UITheme.axisColors` (fields use their theme's).
    public static let axisColors = [UIColor(hex: 0xe5484d), UIColor(hex: 0x46b86a), UIColor(hex: 0x4f8cff), UIColor(hex: 0x9aa1b2)]

    public let fields: [NumberField]

    public var onEditBegan: ((_ start: [Double]) -> Void)?
    public var onChange: ((_ values: [Double]) -> Void)?
    public var onEditEnded: ((_ start: [Double], _ end: [Double]) -> Void)?

    public var range: ClosedRange<Double>? { didSet { for f in fields { f.range = range } } }
    public var step: Double { didSet { for f in fields { f.step = step } } }
    public var precision: Int? { didSet { for f in fields { f.precision = precision } } }

    private var gestureStart: [Double]?

    /// `count` (2...4) components starting at `values` (missing ones are 0).
    public init(count: Int, values: [Double] = [], range: ClosedRange<Double>? = nil, step: Double = 0, name: String = "") {
        let count = min(max(count, 2), 4)
        self.range = range
        self.step = step
        fields = (0..<count).map { i in
            let field = NumberField(value: i < values.count ? values[i] : 0, range: range, step: step,
                                    name: name.isEmpty ? "" : "\(name).\(Self.axisNames[i].lowercased())")
            field.prefix = Self.axisNames[i]
            field.prefixAxis = i  // the theme's axisColors
            field.style.grow = 1
            field.style.width = 0  // equal shares: all width comes from grow
            field.preferredWidth = 40
            return field
        }
        super.init(.horizontal, spacing: 4, alignment: .stretch, name: name, children: fields)
        for field in fields {
            // One precision for the whole vector: the fewest decimals any component fits with
            // ("X 1.0  Y 2.0", not "X 1.00  Y 2.0").
            field.decimalsLimit = { [weak self] in self?.sharedDecimals }
            field.onEditBegan = { [weak self] _ in
                guard let self, self.gestureStart == nil else { return }
                self.gestureStart = self.values
                self.onEditBegan?(self.values)
            }
            field.onChange = { [weak self] _ in
                guard let self else { return }
                self.onChange?(self.values)
            }
            field.onEditEnded = { [weak self] _, _ in
                guard let self, let start = self.gestureStart else { return }
                self.gestureStart = nil
                self.onEditEnded?(start, self.values)
            }
        }
    }

    public var values: [Double] { fields.map(\.value) }

    /// The decimals every component shows while idle: the fewest any of them fits with.
    public var sharedDecimals: Int? {
        fields.filter { !$0.isInteger }.map(\.decimalsThatFit).min()
    }

    /// Whether a component is being dragged or typed into.
    public var isInteracting: Bool { fields.contains { $0.isInteracting } }

    /// Sets the components (no callbacks); ignored while the user is editing one.
    public func setValues(_ values: [Double]) {
        guard !isInteracting else { return }
        for (field, v) in zip(fields, values) { field.setValue(v) }
    }

    public var vec2: Vec2 {
        get { Vec2(Float(fields[0].value), Float(fields[1].value)) }
        set { setValues([Double(newValue.x), Double(newValue.y)]) }
    }

    public var vec3: Vec3 {
        get { Vec3(Float(fields[0].value), Float(fields[1].value), Float(fields[safe: 2]?.value ?? 0)) }
        set { setValues([Double(newValue.x), Double(newValue.y), Double(newValue.z)]) }
    }

    public var vec4: Vec4 {
        get {
            Vec4(Float(fields[0].value), Float(fields[1].value), Float(fields[safe: 2]?.value ?? 0), Float(fields[safe: 3]?.value ?? 0))
        }
        set { setValues([Double(newValue.x), Double(newValue.y), Double(newValue.z), Double(newValue.w)]) }
    }
}

extension Array {
    fileprivate subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
