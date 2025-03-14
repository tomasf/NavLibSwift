import NavLibCpp
import Foundation

internal extension NavLibInstance {
    subscript<T>(getter property: Property<T>) -> (() -> T?)? {
        get { nil }
        set {
            if let newValue {
                getters[property.key] = { newValue()?.value }
            } else {
                getters[property.key] = nil
            }
        }
    }

    subscript<T>(setter property: Property<T>) -> ((T) -> ())? {
        get { nil }
        set {
            if let newValue {
                setters[property.key] = { newValue(.init($0)) }
            } else {
                setters[property.key] = nil
            }
        }
    }

    subscript<T>(property: Property<T>) -> T {
        get {
            var value = navlib.value_t()
            if NavLibIsAvailable() {

                NlReadValue(handle, property.key, &value)
            }
            return T.init(value)
        }
        set {
            guard NavLibIsAvailable() else { return }
            var nlValue = newValue.value
            NlWriteValue(handle, property.key, &nlValue)
        }
    }

    subscript(setting key: String) -> String? {
        get {
            guard NavLibIsAvailable() else { return nil }
            var value = navlib.value_t()
            NlReadValue(handle, "settings." + key, &value)
            guard let pointer = value.string.p else {
                return nil
            }
            let data = Data(bytes: pointer, count: value.string.length)
            return String(data: data, encoding: .utf8) ?? ""
        }
        set {
            guard NavLibIsAvailable() else { return }
            if let newValue {
                var data = Data(newValue.utf8)
                data.withUnsafeMutableBytes { bufferPointer in
                    let bytes = bufferPointer.assumingMemoryBound(to: CChar.self)
                    let string = navlib.string_t(p: bytes.baseAddress, length: bytes.count)
                    var value = navlib.value_t()
                    value.string = string

                    NlWriteValue(handle, "settings." + key, &value)
                }
            } else {
                var value = navlib.value_t()
                value.string.p = nil
                value.string.length = 0
                NlWriteValue(handle, "settings." + key, &value)
            }
        }
    }
}
