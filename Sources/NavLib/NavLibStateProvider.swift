import Foundation

// Adopt this protocol to act as a reader/writer for NavLib
public protocol NavLibStateProvider: AnyObject {
    /// The bounding box of the model in world coordinates.
    var modelBoundingBox: any BoundingBox { get }

    /// This transform specifies the camera to world transformation. NavLib will, generally, query this matrix at the beginning of a navigation action and then set the property once per frame.
    var cameraTransform: any Transform { get set }

    /// The projection type and FOV/ortographic extents of the camera. This is only *set* in orthographic mode, to change the zoom level.
    var cameraProjection: CameraProjection? { get set }

    /// The transform from the client’s coordinate system to the navlib coordinate system.
    var coordinateSystem: (any Transform)? { get }

    var unitsInMeters: Double? { get }
    var frontView: (any Transform)? { get }

    var mousePosition: (any Vector)? { get }
    var selection: Selection? { get }

    func pivotChanged(position: any Vector, visible: Bool)
    func motionActiveChanged(_ active: Bool)
    func hitTest(parameters: HitTest) -> (any Vector)?
}

public extension NavLibStateProvider {
    var cameraProjection: CameraProjection? { get { nil } set {} }

    var unitsInMeters: Double? { nil }
    var frontView: (any Transform)? { nil }
    var coordinateSystem: (any Transform)? { nil }

    var selection: Selection? { nil }

    func pivotChanged(position: any Vector, visible: Bool) {}
    var mousePosition: (any Vector)? { return nil }
    func hitTest(parameters: HitTest) -> (any Vector)? { nil }
    func motionActiveChanged(_ active: Bool) {}
}
