import NavLibCpp
import Foundation

public enum CameraProjection<V: Vector> {
    case perspective (fov: Double) // FOV in degrees
    case orthographic (viewExtents: V.BoundingBox)
}

public struct HitTest<V: Vector> {
    public let diameter: Double
    public let origin: V
    public let direction: V
    public let isSelectionOnly: Bool
}

public struct Selection<V: Vector> {
    public let boundingBox: V.BoundingBox
    public let transform: Transform

    public init(boundingBox: V.BoundingBox, transform: Transform) {
        self.boundingBox = boundingBox
        self.transform = transform
    }
}

public struct Transform {
    public var values: [Double] // 16 values of a 4x4 matrix in row-major order

    public init(_ values: [Double]) {
        self.values = values
    }

    init(_ m: navlib.matrix_t) {
        values = [m.m00, m.m01, m.m02, m.m03,  m.m10, m.m11, m.m12, m.m13,  m.m20, m.m21, m.m22, m.m23,  m.m30, m.m31, m.m32, m.m33]
    }

    var navLibMatrix: navlib.matrix {
        let v = values
        precondition(v.count == 16, "A transform must always contain exactly 16 values.")
        return .init(m00: v[0], m01: v[1], m02: v[2], m03: v[3], m10: v[4], m11: v[5], m12: v[6], m13: v[7], m20: v[8], m21: v[9], m22: v[10], m23: v[11], m30: v[12], m31: v[13], m32: v[14], m33: v[15])
    }

}

// MARK: - Protocols

public protocol Vector {
    associatedtype F: BinaryFloatingPoint
    typealias BoundingBox = (min: Self, max: Self)

    var x: F { get }
    var y: F { get }
    var z: F { get }

    init(x: Double, y: Double, z: Double)
}

// MARK: - Conversions

internal extension Vector {
    var navLibPoint: navlib.point {
        .init(x: Double(x), y: Double(y), z: Double(z))
    }

    init(_ navLibPoint: navlib.point) {
        self.init(x: navLibPoint.x, y: navLibPoint.y, z: navLibPoint.z)
    }

    init(_ navLibVector: navlib.vector) {
        self.init(x: navLibVector.x, y: navLibVector.y, z: navLibVector.z)
    }
}

internal extension navlib.box {
    init<V: Vector>(bounds: V.BoundingBox) {
        self.init(min: bounds.min.navLibPoint, max: bounds.max.navLibPoint)
    }
}
