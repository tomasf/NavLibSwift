import Foundation
import NavLib

public class NavLibSession {
    internal var handle = navlib.nlHandle_t(INVALID_NAVLIB_HANDLE)

    internal var getters: [String: () -> navlib.value_t?] = [:]
    internal var setters: [String: (navlib.value_t) -> ()] = [:]

    public init() {}

    public func start(applicationName: String) throws(InitializationError) {
        guard NavLibIsAvailable() else {
            throw .libraryNotAvailable
        }
        let reference = UInt64(UInt(bitPattern: UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())))

        let accessors = Self.properties.map {
            navlib.accessor_t(
                name: $0,
                fnGet: { NavLibSession.getValue(reference: $0, property: $1, value: $2) },
                fnSet: { NavLibSession.setValue(reference: $0, property: $1, value: $2) },
                param: reference
            )
        }

        let optionsSize = MemoryLayout<navlib.nlCreateOptions_t>.size
        var options = navlib.nlCreateOptions_t(size: UInt32(optionsSize), bMultiThreaded: false, options: navlib.none)

        let creationResult = accessors.withUnsafeBufferPointer { bufferPointer in
            NlCreate(&handle, applicationName, bufferPointer.baseAddress, accessors.count, &options)
        }

        if creationResult != 0 {
            throw .creationError(creationResult)
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

internal extension NavLibSession {
    private static func getValue(reference: navlib.param_t, property: navlib.property_t?, value: UnsafeMutablePointer<navlib.value_t>?) -> Int {
        guard let property, let value else { return navlib.make_result_code(UInt(navlib.navlib_errc.error.rawValue)) }
        let propertyName = String(cString: property)

        let pointer = UnsafeRawPointer(bitPattern: UInt(reference))!
        let session = Unmanaged<NavLibSession>.fromOpaque(pointer).takeUnretainedValue()

        if let getter = session.getters[propertyName], let v = getter() {
            value.pointee = v
            return navlib.make_result_code(0)
        } else {
            // No value available
            return navlib.make_result_code(UInt(navlib.navlib_errc.no_data_available.rawValue))
        }
    }

    private static func setValue(reference: navlib.param_t, property: navlib.property_t?, value: UnsafePointer<navlib.value_t>?) -> Int {
        guard let property, let value else { return navlib.make_result_code(UInt(navlib.navlib_errc.error.rawValue)) }
        let propertyName = String(cString: property)

        let pointer = UnsafeRawPointer(bitPattern: UInt(reference))!
        let session = Unmanaged<NavLibSession>.fromOpaque(pointer).takeUnretainedValue()

        if let setter = session.setters[propertyName] {
            setter(value.pointee)
            return navlib.make_result_code(0)
        } else {
            // No value available
            return navlib.make_result_code(UInt(navlib.navlib_errc.no_data_available.rawValue))
        }
    }
}

public extension NavLibSession {
    enum InitializationError: Error {
        case libraryNotAvailable
        case creationError (Int)
    }
}

