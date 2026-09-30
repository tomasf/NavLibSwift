import NavLibCpp
import Foundation

/// The projection type used by a camera in the 3D view.
///
/// NavLib uses this information to understand how the scene is being rendered,
/// which affects navigation behavior such as zooming.
public enum CameraProjection<V: Vector> {
    /// Perspective projection with a specified field of view.
    ///
    /// - Parameter fov: The vertical field of view in degrees.
    case perspective (fov: Double)

    /// Orthographic projection with specified view extents.
    ///
    /// - Parameter viewExtents: The bounding box defining the visible area in view coordinates.
    case orthographic (viewExtents: V.BoundingBox)
}

/// Parameters for performing a hit test against scene geometry.
///
/// NavLib uses hit testing to find the pivot point for rotation operations.
/// When the user moves the SpaceMouse, NavLib may request a hit test to
/// determine what geometry is under the cursor or along the view direction.
public struct HitTest<V: Vector> {
    /// The aperture diameter for cone-based hit testing.
    ///
    /// This defines the width of the selection cone, useful for selecting
    /// small objects that might otherwise be difficult to hit precisely.
    public let diameter: Double

    /// The origin point of the hit test ray, typically the camera position.
    public let origin: V

    /// The direction vector of the hit test ray.
    public let direction: V

    /// Whether to test only against selected geometry.
    ///
    /// When `true`, the hit test should only consider currently selected objects.
    public let isSelectionOnly: Bool
}

/// Describes the currently selected geometry in the scene.
///
/// NavLib uses selection information to calculate appropriate pivot points
/// and to optimize navigation around selected objects.
public struct Selection<V: Vector> {
    /// The axis-aligned bounding box of the selected geometry in local coordinates.
    public let boundingBox: V.BoundingBox

    /// The transformation matrix from local selection space to world space.
    public let transform: Transform

    /// Creates a new selection descriptor.
    ///
    /// - Parameters:
    ///   - boundingBox: The bounding box of the selection in local coordinates.
    ///   - transform: The transform from local to world coordinates.
    public init(boundingBox: V.BoundingBox, transform: Transform) {
        self.boundingBox = boundingBox
        self.transform = transform
    }
}

/// A homogeneous 4×4 transformation matrix.
///
/// This type represents affine transformations including rotation, translation,
/// and scaling. It is used throughout NavLib to represent camera transforms,
/// coordinate system transforms, and object transforms.
///
/// The matrix is stored in row-major order, meaning the first four values
/// represent the first row of the matrix.
public struct Transform {
    /// The 16 values of the 4×4 matrix in row-major order.
    ///
    /// The layout is:
    /// ```
    /// [ m00, m01, m02, m03,   // Row 0
    ///   m10, m11, m12, m13,   // Row 1
    ///   m20, m21, m22, m23,   // Row 2
    ///   m30, m31, m32, m33 ]  // Row 3
    /// ```
    public var values: [Double]

    /// Creates a transform from an array of 16 values in row-major order.
    ///
    /// - Parameter values: An array of exactly 16 `Double` values representing
    ///   the 4×4 matrix in row-major order.
    /// - Precondition: The array must contain exactly 16 elements.
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

/// A protocol for 3D vector types that can be used with NavLib.
///
/// Conform your own vector type to this protocol to use it with ``NavLibSession``
/// and ``NavLibStateProvider``. This allows NavLib to work with any 3D vector
/// implementation, such as SIMD types, SceneKit vectors, or custom types.
///
/// ## Conforming to Vector
///
/// To conform to `Vector`, provide the `x`, `y`, and `z` components as readable
/// properties and an initializer that accepts `Double` values:
///
/// ```swift
/// struct MyVector: Vector {
///     var x, y, z: Double
///
///     init(x: Double, y: Double, z: Double) {
///         self.x = x
///         self.y = y
///         self.z = z
///     }
/// }
/// ```
public protocol Vector {
    /// The floating-point type used for the vector's components.
    associatedtype F: BinaryFloatingPoint

    /// A tuple representing an axis-aligned bounding box with minimum and maximum corners.
    typealias BoundingBox = (min: Self, max: Self)

    /// The x component of the vector.
    var x: F { get }

    /// The y component of the vector.
    var y: F { get }

    /// The z component of the vector.
    var z: F { get }

    /// Creates a vector from the given double-precision components.
    ///
    /// - Parameters:
    ///   - x: The x component.
    ///   - y: The y component.
    ///   - z: The z component.
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
