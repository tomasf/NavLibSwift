import NavLibCpp
import Foundation

/// A session that manages communication with 3DConnexion SpaceMouse devices.
///
/// `NavLibSession` is the main entry point for integrating SpaceMouse support into
/// your application. Create a session, provide a ``NavLibStateProvider``, and start
/// the session to begin receiving navigation input.
///
/// ## Overview
///
/// Each `NavLibSession` represents a single 3D view that can receive SpaceMouse input.
/// For applications with multiple 3D views, create a separate session for each view
/// and use ``setAsActiveSession()`` to switch which view receives input.
///
/// ## Getting Started
///
/// ```swift
/// // 1. Create a session
/// let session = NavLibSession<MyVector>()
///
/// // 2. Create your state provider
/// let provider = MySceneProvider()
///
/// // 3. Start the session
/// do {
///     try session.start(stateProvider: provider, applicationName: "MyApp")
/// } catch .libraryNotAvailable {
///     // 3DConnexion drivers not installed - gracefully degrade
/// } catch .navLibError(let code) {
///     print("NavLib error: \(code)")
/// }
/// ```
///
/// ## Dynamic Framework Loading
///
/// This library dynamically loads the 3DConnexion framework at runtime. Your application
/// will work even if users don't have the 3DConnexion drivers installed - the session
/// will simply throw ``InitializationError/libraryNotAvailable`` when started.
///
/// For apps distributed outside the Mac App Store that use Hardened Runtime, you must
/// add the `com.apple.security.cs.disable-library-validation` entitlement.
public final class NavLibSession<V: Vector> {
    private let instance = NavLibInstance()

    /// Creates a new NavLib session.
    ///
    /// After creating a session, call ``start(stateProvider:applicationName:)`` to
    /// initialize the connection to the SpaceMouse drivers.
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

    /// The state provider currently associated with this session.
    ///
    /// This is set automatically when you call ``start(stateProvider:applicationName:)``.
    /// The session holds a weak reference to avoid retain cycles.
    public weak var stateProvider: (any NavLibStateProvider<V>)?

    /// Starts the session and connects to the SpaceMouse drivers.
    ///
    /// Call this method to initialize the connection to 3DConnexion's NavLib framework.
    /// The session will begin querying your state provider for scene information and
    /// will update the camera transform as the user moves the SpaceMouse.
    ///
    /// - Parameters:
    ///   - stateProvider: An object that provides scene state and receives navigation updates.
    ///   - applicationName: Your application's name, displayed in the 3DConnexion configuration UI.
    /// - Throws: ``InitializationError/libraryNotAvailable`` if the 3DConnexion drivers are not
    ///   installed, or ``InitializationError/navLibError(code:)`` if initialization fails.
    public func start(stateProvider: any NavLibStateProvider<V>, applicationName: String) throws(InitializationError) {
        self.stateProvider = stateProvider
        try instance.start(applicationName: applicationName)
    }

    /// Overrides the automatic pivot point calculation with a specific position.
    ///
    /// By default, NavLib calculates the pivot point automatically based on scene
    /// geometry and hit testing. Set this property to force a specific pivot point.
    /// Set to `nil` to return to automatic pivot calculation.
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
    /// Cancels any ongoing navigation motion.
    ///
    /// Call this to immediately stop camera movement, for example when the user
    /// performs an action that should interrupt navigation.
    func cancelMotion() {
        instance[.motion] = false
    }

    /// Makes this session the active receiver of SpaceMouse input.
    ///
    /// In applications with multiple 3D views (and thus multiple sessions),
    /// call this method when a view gains focus to direct SpaceMouse input to it.
    func setAsActiveSession() {
        instance[.active] = true
    }

    /// Indicates whether the application currently has focus.
    ///
    /// Set this to `true` when your application becomes active and `false` when
    /// it loses focus. NavLib uses this to determine whether to process input.
    var applicationHasFocus: Bool {
        get { instance[.focus] }
        set { instance[.focus] = newValue }
    }

    /// The current mouse position in 3D world coordinates.
    ///
    /// Update this property when the mouse moves over your 3D view. NavLib may
    /// use this position for pivot point calculation.
    var mousePosition: V {
        get {
            .init(instance[.pointerPosition])
        }
        set {
            instance[.pointerPosition] = newValue.navLibPoint
        }
    }

    /// The current camera projection type and parameters.
    ///
    /// Read this to get the current projection settings, or set it to change
    /// between perspective and orthographic modes.
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

    /// Enables or disables manual frame timing mode.
    ///
    /// When `true`, you must call ``startFrame(at:)`` at the beginning of each
    /// frame to provide timing information to NavLib. When `false` (the default),
    /// NavLib manages timing automatically.
    ///
    /// Use manual frame timing when you need precise synchronization between
    /// NavLib updates and your render loop.
    var useManualFrameTiming: Bool {
        get { instance[.frameTimingSource] == 1 }
        set { instance[.frameTimingSource] = newValue ? 1 : 0 }
    }

    /// Signals the start of a new frame when using manual frame timing.
    ///
    /// Call this at the beginning of each frame when ``useManualFrameTiming`` is `true`.
    /// This provides NavLib with timing information for smooth navigation.
    ///
    /// - Parameter time: The timestamp of the frame, typically from `CACurrentMediaTime()`.
    func startFrame(at time: TimeInterval) {
        instance[.frameTime] = time * 1000.0
    }

    /// Accesses NavLib configuration settings by key.
    ///
    /// Use this subscript to read or write NavLib settings. Available settings
    /// depend on the NavLib version and configuration.
    ///
    /// - Parameter key: The setting key string.
    /// - Returns: The setting value, or `nil` if the setting doesn't exist.
    subscript(setting key: String) -> String? {
        get { instance[setting: key] }
        set { instance[setting: key] = newValue }
    }
}
