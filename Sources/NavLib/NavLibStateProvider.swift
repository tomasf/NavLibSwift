import Foundation

// Adopt this protocol to act as a reader/writer for NavLib
public protocol NavLibStateProvider <V>: AnyObject {
    associatedtype V: Vector

    /// The bounding box of the model in world coordinates.
    var modelBoundingBox: V.BoundingBox { get }

    /// This transform specifies the camera to world transformation. NavLib will, generally, query this matrix at the beginning of a navigation action and then set the property once per frame.
    var cameraTransform: Transform { get set }

    /// The projection type and FOV/ortographic extents of the camera. This is only *set* in orthographic mode, to change the zoom level.
    var cameraProjection: CameraProjection<V>? { get set }

    /// The transform from the client’s coordinate system to the navlib coordinate system.
    var coordinateSystem: Transform? { get }

    var unitsInMeters: Double? { get }
    var frontView: Transform? { get }

    var mousePosition: V? { get }
    var selection: Selection<V>? { get }

    func pivotChanged(position: V, visible: Bool)
    func motionActiveChanged(_ active: Bool)
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
