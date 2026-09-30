import Foundation

/// A protocol that provides scene state to NavLib and receives navigation updates.
///
/// Implement this protocol to connect your 3D view to a ``NavLibSession``. Your
/// implementation provides information about the scene (camera position, model bounds,
/// selection) and receives updates when NavLib computes new camera positions based
/// on SpaceMouse input.
///
/// ## Required Properties
///
/// At minimum, you must implement:
/// - ``modelBoundingBox``: The bounds of your 3D content
/// - ``cameraTransform``: Your camera's current position and orientation
///
/// ## Example
///
/// ```swift
/// class MySceneProvider: NavLibStateProvider {
///     var modelBoundingBox: MyVector.BoundingBox {
///         return (min: .init(x: -10, y: -10, z: -10),
///                 max: .init(x: 10, y: 10, z: 10))
///     }
///
///     var cameraTransform: Transform {
///         get { /* return current camera transform */ }
///         set { /* update camera and redraw */ }
///     }
/// }
/// ```
public protocol NavLibStateProvider<V>: AnyObject {
    /// The vector type used for 3D coordinates in this provider.
    associatedtype V: Vector

    /// The axis-aligned bounding box of the model in world coordinates.
    ///
    /// NavLib uses this to understand the scale of the scene and to calculate
    /// appropriate navigation speeds and pivot points.
    var modelBoundingBox: V.BoundingBox { get }

    /// The camera-to-world transformation matrix.
    ///
    /// This transform positions and orients the camera in world space.
    /// NavLib reads this at the beginning of a navigation action and writes
    /// to it once per frame during navigation to update the camera position.
    ///
    /// When this property is set, you should update your view's camera and
    /// trigger a redraw.
    var cameraTransform: Transform { get set }

    /// The camera's projection type and parameters.
    ///
    /// Provide `.perspective(fov:)` for perspective cameras or
    /// `.orthographic(viewExtents:)` for orthographic cameras.
    ///
    /// NavLib may set this property during navigation in orthographic mode
    /// to adjust the zoom level.
    var cameraProjection: CameraProjection<V>? { get set }

    /// The transformation from your coordinate system to NavLib's coordinate system.
    ///
    /// If your application uses a different coordinate system convention than NavLib
    /// (which uses a right-handed Y-up system), provide a transform here to convert
    /// between them. Return `nil` to use NavLib's native coordinate system.
    var coordinateSystem: Transform? { get }

    /// The scale factor to convert your units to meters.
    ///
    /// NavLib uses real-world units internally. If your scene uses different units,
    /// provide the conversion factor here. For example, if your scene uses centimeters,
    /// return `0.01`.
    var unitsInMeters: Double? { get }

    /// The transformation matrix for the "front" view of the model.
    ///
    /// This is used by NavLib to provide a canonical front view orientation.
    /// Return `nil` if not applicable.
    var frontView: Transform? { get }

    /// The current mouse or pointer position in 3D space.
    ///
    /// NavLib may use this to determine pivot points for rotation.
    /// Return `nil` if mouse position tracking is not available.
    var mousePosition: V? { get }

    /// The currently selected geometry, if any.
    ///
    /// When objects are selected in your scene, provide their bounds and transform
    /// here. NavLib uses selection information to calculate appropriate pivot points.
    var selection: Selection<V>? { get }

    /// Called when NavLib updates the pivot point position or visibility.
    ///
    /// You can use this to display a visual indicator at the pivot point.
    ///
    /// - Parameters:
    ///   - position: The pivot point position in world coordinates.
    ///   - visible: Whether the pivot point should be displayed.
    func pivotChanged(position: V, visible: Bool)

    /// Called when motion input starts or stops.
    ///
    /// You can use this to optimize rendering or update UI state.
    ///
    /// - Parameter active: `true` when motion begins, `false` when it ends.
    func motionActiveChanged(_ active: Bool)

    /// Performs a hit test against scene geometry.
    ///
    /// NavLib calls this to find intersection points for calculating pivot points.
    /// Implement this to cast a ray into your scene and return the intersection point.
    ///
    /// - Parameter parameters: The hit test parameters including ray origin and direction.
    /// - Returns: The intersection point in world coordinates, or `nil` if no hit.
    func hitTest(parameters: HitTest<V>) -> V?
}

public extension NavLibStateProvider {
    var cameraProjection: CameraProjection<V>? { get { nil } set {} }

    var unitsInMeters: Double? { nil }
    var frontView: Transform? { nil }
    var coordinateSystem: Transform? { nil }

    var selection: Selection<V>? { nil }

    func pivotChanged(position: V, visible: Bool) {}
    var mousePosition: V? { return nil }
    func hitTest(parameters: HitTest<V>) -> V? { nil }
    func motionActiveChanged(_ active: Bool) {}
}
