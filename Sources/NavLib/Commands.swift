import Foundation
import NavLibCpp

/// An application command, or a group of them, that the user can assign to 3DMouse buttons in the
/// 3Dconnexion configuration UI. Register a list of these with
/// ``NavLibSession/registerCommands(_:setID:)``.
///
/// ```swift
/// try session.registerCommands([
///     .category(id: "views", label: "Views", children: [
///         .action(id: "view.front", label: "Front View", description: "Show the front view"),
///         .action(id: "view.top", label: "Top View"),
///     ]),
///     .action(id: "file.export", label: "Export"),
/// ], setID: "my-app")
/// ```
///
/// Identifiers must remain constant across application releases and must not be localized, since
/// the user's button assignments refer to them. Labels and descriptions are user-facing and can be
/// localized.
public enum NavLibCommand: Sendable {
    /// An assignable command. `id` is reported back through ``NavLibSession/commandHandler`` when
    /// the user presses a button mapped to it. `description` is shown as a tooltip.
    case action(id: String, label: String, description: String? = nil)

    /// A group of commands, shown as an expandable item. Categories can be nested.
    case category(id: String, label: String, children: [NavLibCommand])
}

/// Errors thrown by ``NavLibSession/registerCommands(_:setID:)``.
public enum CommandRegistrationError: Error {
    /// The 3DConnexion NavLib framework is not available, typically because the drivers aren't
    /// installed.
    case libraryNotAvailable

    /// The session hasn't been started with ``NavLibSession/start(stateProvider:applicationName:)``.
    case sessionNotStarted

    /// NavLib rejected the commands.
    ///
    /// - Parameter code: The error code returned by the NavLib framework.
    case navLibError(code: Int)
}

internal extension NavLibCommand {
    struct FlatNode {
        let type: SiActionNodeType_t
        let id: String
        let label: String?
        let description: String?
        let parent: Int
    }

    /// The command tree under an action-set root with id `setID`, in pre-order, each node referring
    /// to its parent by index, as `NlWriteCommandTree` expects.
    static func flattened(_ commands: [NavLibCommand], setID: String) -> [FlatNode] {
        var nodes = [FlatNode(type: SI_ACTIONSET_NODE, id: setID, label: nil, description: nil, parent: -1)]

        func append(_ commands: [NavLibCommand], parent: Int) {
            for command in commands {
                switch command {
                case .action(let id, let label, let description):
                    nodes.append(FlatNode(type: SI_ACTION_NODE, id: id, label: label, description: description, parent: parent))
                case .category(let id, let label, let children):
                    let index = nodes.count
                    nodes.append(FlatNode(type: SI_CATEGORY_NODE, id: id, label: label, description: nil, parent: parent))
                    append(children, parent: index)
                }
            }
        }

        append(commands, parent: 0)
        return nodes
    }
}

internal extension navlib.value_t {
    /// Decodes a `string_type` value (such as `commands.activeCommand`) into a Swift string.
    var navLibString: String? {
        guard let pointer = string.p, string.length > 0 else { return nil }
        let data = Data(bytes: pointer, count: string.length)
        var result = String(data: data, encoding: .utf8)
        // The navlib may include the trailing NUL in `length`; drop it for clean comparisons.
        if result?.last == "\0" { result?.removeLast() }
        return result
    }
}

internal extension NavLibInstance {
    /// The navlib property name the navlib writes when a button-mapped command is activated.
    static let activeCommandPropertyName = String(cString: navlib.commands_activeCommand_k)

    /// Marshals `commands` into C strings and pushes them to the navlib `commands.tree` property as
    /// the action set `setID`.
    func writeCommands(_ commands: [NavLibCommand], setID: String) throws(CommandRegistrationError) {
        guard NavLibIsAvailable() else { throw .libraryNotAvailable }
        guard handle != navlib.nlHandle_t(INVALID_NAVLIB_HANDLE) else { throw .sessionNotStarted }

        // strdup'd copies kept alive (via the defer) for the duration of the write call.
        var allocations: [UnsafeMutablePointer<CChar>] = []
        defer { allocations.forEach { free($0) } }
        func copy(_ string: String?) -> UnsafePointer<CChar>? {
            guard let string, let pointer = strdup(string) else { return nil }
            allocations.append(pointer)
            return UnsafePointer(pointer)
        }

        let nodes = NavLibCommand.flattened(commands, setID: setID).map {
            NlCommandNode(type: $0.type, id: copy($0.id), label: copy($0.label), description: copy($0.description), parent: $0.parent)
        }
        let result = nodes.withUnsafeBufferPointer {
            NlWriteCommandTree(handle, $0.baseAddress, $0.count)
        }
        if result != 0 { throw .navLibError(code: result) }
    }
}
