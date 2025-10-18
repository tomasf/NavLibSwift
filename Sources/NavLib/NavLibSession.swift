import NavLibCpp
import Foundation

public final class NavLibSession<V: Vector> {
    private let instance = NavLibInstance()

    public init() {
        instance[getter: .modelExtents] = { [weak self] in
            guard let bounds = self?.stateProvider?.modelBoundingBox else { return nil }
            return navlib.box(bounds: bounds)
        }
        instance[getter: .cameraTransform] = { [weak self] in self?.stateProvider?.cameraTransform.navLibMatrix }
        instance[setter: .cameraTransform] = { [weak self] in self?.stateProvider?.cameraTransform = .init($0) }
        instance[getter: .unitsToMeters] = { [weak self] in self?.stateProvider?.unitsInMeters }
        instance[getter: .frontView] = { [weak self] in self?.stateProvider?.frontView?.navLibMatrix }
        instance[getter: .pointerPosition] = { [weak self] in self?.stateProvider?.mousePosition?.navLibPoint }
        instance[getter: .hasEmptySelection] = { [weak self] in self?.stateProvider?.selection == nil }
        instance[getter: .selectionExtents] = { [weak self] in
            guard let bounds = self?.stateProvider?.selection?.boundingBox else { return nil }
            return .init(bounds: bounds)
        }
        instance[getter: .selectionTransform] = { [weak self] in self?.stateProvider?.selection?.transform.navLibMatrix }
        instance[setter: .motion] = { [weak self] in self?.stateProvider?.motionActiveChanged($0) }
        instance[getter: .coordinateSystem] = { [weak self] in self?.stateProvider?.coordinateSystem?.navLibMatrix }

        instance[getter: .viewFOV] = { [weak self] in
            guard let projection = self?.stateProvider?.cameraProjection,
                  case .perspective(let fov) = projection
            else { return nil }

            return fov / 180.0 * Double.pi
        }

        instance[getter: .viewIsPerspective] = { [weak self] in
            guard let projection = self?.stateProvider?.cameraProjection else { return nil }
            if case .perspective = projection {
                return true
            } else {
                return false
            }
        }

        instance[getter: .orthographicViewExtents] = { [weak self] in
            guard let projection = self?.stateProvider?.cameraProjection,
                  case .orthographic(let viewExtents) = projection
            else { return nil }

            return .init(bounds: viewExtents)
        }

        instance[setter: .orthographicViewExtents] = { [weak self] in
            self?.stateProvider?.cameraProjection = .orthographic(viewExtents: (.init($0.min), .init($0.max)))
        }

        instance[setter: .pivotPosition] = { [weak self] in
            guard let self else { return }
            let visibility = self.instance[.pivotIsVisible]
            self.stateProvider?.pivotChanged(position: .init($0), visible: visibility)
        }

        instance[setter: .pivotIsVisible] = { [weak self] in
            guard let self else { return }
            let position = self.instance[.pivotPosition]
            self.stateProvider?.pivotChanged(position: .init(position), visible: $0)
        }

        instance[getter: .hitTestingTarget] = { [weak self] in
            guard let self else { return nil }

            let parameters = HitTest<V>(
                diameter: instance[.hitTestingDiameter],
                origin: .init(instance[.hitTestingOrigin]),
                direction: .init(instance[.hitTestingDirection]),
                isSelectionOnly: instance[.hitTestingSelectionOnly]
            )

            return self.stateProvider?.hitTest(parameters: parameters)?.navLibPoint
        }
    }

    public weak var stateProvider: (any NavLibStateProvider<V>)?

    public func start(stateProvider: any NavLibStateProvider<V>, applicationName: String) throws(InitializationError) {
        self.stateProvider = stateProvider
        try instance.start(applicationName: applicationName)
    }

    public var pivotPointOverride: (any Vector)? {
        didSet {
            if let pivotPointOverride {
                instance[.pivotPosition] = pivotPointOverride.navLibPoint
            } else {
                instance[.hasPivotOverride] = false
            }
        }
    }
}

public extension NavLibSession {
    func cancelMotion() {
        instance[.motion] = false
    }

    func setAsActiveSession() {
        instance[.active] = true
    }

    var applicationHasFocus: Bool {
        get { instance[.focus] }
        set { instance[.focus] = newValue }
    }

    var mousePosition: V {
        get {
            .init(instance[.pointerPosition])
        }
        set {
            instance[.pointerPosition] = newValue.navLibPoint
        }
    }

    var cameraProjection: CameraProjection<V> {
        get {
            if instance[.viewIsPerspective] {
                let fov = instance[.viewFOV] / Double.pi * 180.0
                return .perspective(fov: fov)
            } else {
                let extents = instance[.orthographicViewExtents]
                return .orthographic(viewExtents: (.init(extents.min), .init(extents.max)))
            }
        }
        set {
            switch newValue {
            case .orthographic (let extents):
                instance[.viewIsPerspective] = false
                instance[.orthographicViewExtents] = .init(bounds: extents)

            case .perspective (let fov):
                instance[.viewIsPerspective] = true
                instance[.viewFOV] = fov / 180.0 * Double.pi
            }
        }
    }

    var useManualFrameTiming: Bool {
        get { instance[.frameTimingSource] == 1 }
        set { instance[.frameTimingSource] = newValue ? 1 : 0 }
    }

    func startFrame(at time: TimeInterval) {
        instance[.frameTime] = time * 1000.0
    }

    subscript(setting key: String) -> String? {
        get { instance[setting: key] }
        set { instance[setting: key] = newValue }
    }
}
