import Foundation
import NavLibCpp

internal final class NavLibInstance {
    internal var handle = navlib.nlHandle_t(INVALID_NAVLIB_HANDLE)

    internal var getters: [String: () -> navlib.value_t?] = [:]
    internal var setters: [String: (navlib.value_t) -> ()] = [:]

    internal let callbackQueue: DispatchQueue?

    init(callbackQueue: DispatchQueue? = nil) {
        self.callbackQueue = callbackQueue
    }

    public func start(applicationName: String) throws(InitializationError) {
        guard NavLibIsAvailable() else {
            throw .libraryNotAvailable
        }
        let reference = UInt64(UInt(bitPattern: UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())))

        let accessors = Self.properties.map {
            navlib.accessor_t(
                name: $0,
                fnGet: { NavLibInstance.getValue(reference: $0, property: $1, value: $2) },
                fnSet: { NavLibInstance.setValue(reference: $0, property: $1, value: $2) },
                param: reference
            )
        }

        let optionsSize = MemoryLayout<navlib.nlCreateOptions_t>.size
        var options = navlib.nlCreateOptions_t(size: UInt32(optionsSize), bMultiThreaded: callbackQueue != nil, options: navlib.none)

        let creationResult = accessors.withUnsafeBufferPointer { bufferPointer in
            NlCreate(&handle, applicationName, bufferPointer.baseAddress, accessors.count, &options)
        }

        if creationResult != 0 {
            throw .navLibError(code: creationResult)
        }
    }

    deinit {
        invalidate()
    }

    public func invalidate() {
        if handle != navlib.nlHandle_t(INVALID_NAVLIB_HANDLE) {
            NlClose(handle)
            handle = navlib.nlHandle_t(INVALID_NAVLIB_HANDLE)
        }
    }
}

internal extension NavLibInstance {
    private static let resultSuccess = navlib.make_result_code(0)
    private static let resultError = navlib.make_result_code(UInt(navlib.navlib_errc.error.rawValue))
    private static let resultNoData = navlib.make_result_code(UInt(navlib.navlib_errc.no_data_available.rawValue))

    private static func getValue(reference: navlib.param_t, property: navlib.property_t?, value: UnsafeMutablePointer<navlib.value_t>?) -> Int {
        guard let property, let value else { return resultError }
        let propertyName = String(cString: property)

        let pointer = UnsafeRawPointer(bitPattern: UInt(reference))!
        let instance = Unmanaged<NavLibInstance>.fromOpaque(pointer).takeUnretainedValue()

        guard let getter = instance.getters[propertyName] else {
            return resultNoData
        }

        if let queue = instance.callbackQueue {
            var result: navlib.value_t?
            queue.sync {
                result = getter()
            }
            if let v = result {
                value.pointee = v
                return resultSuccess
            }
        } else if let v = getter() {
            value.pointee = v
            return resultSuccess
        }

        return resultNoData
    }

    private static func setValue(reference: navlib.param_t, property: navlib.property_t?, value: UnsafePointer<navlib.value_t>?) -> Int {
        guard let property, let value else { return resultError }
        let propertyName = String(cString: property)

        let pointer = UnsafeRawPointer(bitPattern: UInt(reference))!
        let instance = Unmanaged<NavLibInstance>.fromOpaque(pointer).takeUnretainedValue()

        guard let setter = instance.setters[propertyName] else {
            return resultNoData
        }

        if let queue = instance.callbackQueue {
            queue.sync {
                setter(value.pointee)
            }
        } else {
            setter(value.pointee)
        }

        return resultSuccess
    }
}

/// Errors that can occur when starting a ``NavLibSession``.
///
/// These errors indicate problems initializing the connection to the
/// 3DConnexion SpaceMouse drivers.
public enum InitializationError: Error {
    /// The 3DConnexion NavLib framework is not available.
    ///
    /// This typically means the 3DConnexion drivers are not installed on the system.
    /// Your application should handle this gracefully by disabling SpaceMouse features.
    case libraryNotAvailable

    /// NavLib returned an error during initialization.
    ///
    /// - Parameter code: The error code returned by the NavLib framework.
    case navLibError(code: Int)
}
