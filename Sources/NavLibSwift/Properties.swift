import NavLib
import Foundation

internal extension NavLibSession {
    static var properties: [navlib.property_t] {
        [navlib.active_k, navlib.focus_k, navlib.motion_k, navlib.coordinate_system_k, navlib.transaction_k, navlib.frame_time_k, navlib.frame_timing_source_k, navlib.device_present_k, navlib.commands_tree_k, navlib.commands_activeCommand_k, navlib.commands_activeSet_k, navlib.images_k, navlib.view_affine_k, navlib.view_constructionPlane_k, navlib.view_extents_k, navlib.view_fov_k, navlib.view_frustum_k, navlib.view_perspective_k, navlib.view_target_k, navlib.view_rotatable_k, navlib.view_focusDistance_k, navlib.views_front_k, navlib.pivot_position_k, navlib.pivot_user_k, navlib.pivot_visible_k, navlib.hit_lookfrom_k, navlib.hit_direction_k, navlib.hit_aperture_k, navlib.hit_lookat_k, navlib.hit_selectionOnly_k, navlib.selection_affine_k, navlib.selection_empty_k, navlib.selection_extents_k, navlib.model_extents_k, navlib.model_floorPlane_k, navlib.model_unitsToMeters_k, navlib.pointer_position_k, navlib.events_keyPress_k, navlib.events_keyRelease_k, navlib.settings_changed_k]
    }
}

public extension NavLibSession {
    struct Property <T: NavLibValue>: Sendable {
        let key: String

        internal init(_ key: navlib.property_t) {
            self.key = String(cString: key)
        }
    }
}

public extension NavLibSession.Property where T == Int {
    static let settingsChanged = Self(navlib.settings_changed_k)
    static let keyPressed = Self(navlib.events_keyPress_k)
    static let keyReleased = Self(navlib.events_keyRelease_k)
    static let transaction = Self(navlib.transaction_k)
}

public extension NavLibSession.Property where T == Double {
    static let unitsToMeters = Self(navlib.model_unitsToMeters_k)
    static let viewFOV = Self(navlib.view_fov_k)
    static let hitTestingDiameter = Self(navlib.hit_aperture_k)
}

public extension NavLibSession.Property where T == Bool {
    static let hitTestingSelectionOnly = Self(navlib.hit_selectionOnly_k)
    static let active = Self(navlib.active_k)
    static let focus = Self(navlib.focus_k)
    static let motion = Self(navlib.motion_k)
    static let devicePresent = Self(navlib.device_present_k)
    static let viewIsPerspective = Self(navlib.view_perspective_k)
    static let pivotIsVisible = Self(navlib.pivot_visible_k)
    static let hasEmptySelection = Self(navlib.selection_empty_k)
}

public extension NavLibSession.Property where T == navlib.matrix_t {
    static let cameraTransform = Self(navlib.view_affine_k)
    static let coordinateSystem = Self(navlib.coordinate_system_k)
    static let frontView = Self(navlib.views_front_k)
}

public extension NavLibSession.Property where T == navlib.box_t {
    static let modelExtents = Self(navlib.model_extents_k)
    static let orthographicViewExtents = Self(navlib.view_extents_k)
}

public extension NavLibSession.Property where T == navlib.point_t {
    static let pivotPosition = Self(navlib.pivot_position_k)
    static let pointerPosition = Self(navlib.pointer_position_k)
    static let hitTestingOrigin = Self(navlib.hit_lookfrom_k)
    static let hitTestingTarget = Self(navlib.hit_lookat_k)
}

public extension NavLibSession.Property where T == navlib.vector_t {
    static let hitTestingDirection = Self(navlib.hit_direction_k)
}
