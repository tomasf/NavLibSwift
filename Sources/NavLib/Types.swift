import NavLibCpp
import Foundation

public enum CameraProjection {
    case perspective (fov: Double) // FOV in radians
    case orthographic (viewExtents: any BoundingBox)
}

public struct HitTest {
    public let diameter: Double
    public let origin: any Vector
    public let direction: any Vector
    public let isSelectionOnly: Bool
}

public struct Selection {
    public let boundingBox: any BoundingBox
    public let transform: any Transform

    public init(boundingBox: any BoundingBox, transform: any Transform) {
        self.boundingBox = boundingBox
        self.transform = transform
    }
}

// MARK: - Protocols

public protocol Vector {
    associatedtype F: BinaryFloatingPoint
    var x: F { get }
    var y: F { get }
    var z: F { get }
}

public protocol BoundingBox {
    associatedtype V: Vector
    var min: V { get }
    var max: V { get }
}

public protocol Transform {
    var values: [Double] { get } // 16 values of a 4x4 matrix in row-major order (row 1, column 1, row 1, column 2...)
}

// MARK: - NavLib extensions

extension navlib.point: Vector {}
extension navlib.vector: Vector {}
extension navlib.box: BoundingBox {}

extension navlib.matrix: Transform {
    public var values: [Double] {
        [m00, m01, m02, m03,  m10, m11, m12, m13,  m20, m21, m22, m23,  m30, m31, m32, m33]
    }
}

// MARK: - Conversions

internal extension Vector {
    var navLibPoint: navlib.point {
        .init(x: Double(x), y: Double(y), z: Double(z))
    }
}

internal extension BoundingBox {
    var navLibBox: navlib.box {
        .init(min: min.navLibPoint, max: max.navLibPoint)
    }
}

extension Transform {
    var navLibMatrix: navlib.matrix {
        let v = values
        precondition(v.count == 16, "A transform must always contain exactly 16 values.")
        return .init(m00: v[0], m01: v[1], m02: v[2], m03: v[3], m10: v[4], m11: v[5], m12: v[6], m13: v[7], m20: v[8], m21: v[9], m22: v[10], m23: v[11], m30: v[12], m31: v[13], m32: v[14], m33: v[15])
    }
}
