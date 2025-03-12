import NavLib
import Foundation

public protocol NavLibValue {
    init(_ value: navlib.value_t)
    var value: navlib.value_t { get }
}

extension Int: NavLibValue {
    public init(_ value: navlib.value_t) { self = value.l }
    public var value: navlib.value_t { .init(self) }
}

extension Double: NavLibValue {
    public init(_ value: navlib.value_t) { self = value.d }
    public var value: navlib.value_t { .init(self) }
}

extension Bool: NavLibValue {
    public init(_ value: navlib.value_t) { self = value.b != 0 }
    public var value: navlib.value_t { .init(self) }
}

extension navlib.matrix_t: NavLibValue {
    public init(_ value: navlib.value_t) { self = value.matrix }
    public var value: navlib.value_t { .init(self) }
}

extension navlib.box_t: NavLibValue {
    public init(_ value: navlib.value_t) { self = value.box }
    public var value: navlib.value_t { .init(self) }
}

extension navlib.point_t: NavLibValue {
    public init(_ value: navlib.value_t) { self = value.point }
    public var value: navlib.value_t { .init(self) }
}

extension navlib.vector_t: NavLibValue {
    public init(_ value: navlib.value_t) { self = value.vector }
    public var value: navlib.value_t { .init(self) }
}
