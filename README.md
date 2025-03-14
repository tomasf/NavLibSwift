# NavLibSwift

NavLibSwift is a Swift package for interfacing with 3DConnexion's Navigation Framework (NavLib) on macOS. This allows you to add support for their SpaceMouse line of 3D controllers to your application and makes it easier than ever.

## Usage

### Add the 3DconnexionNavLib Library

1. Ensure you have installed 3DConnexion's 3DxWare software. This installs the framework into `/Library/Frameworks`.
2. Link against `3DconnexionNavLib`, but do *not* import it directly, as the provided headers are broken.
3. Weak-link the framework to allow your app to run even if the library is not installed. Add `-weak_framework 3DconnexionNavLib` to your Linker Flags to accomplish this.

### Add the NavLibSwift Package

1. Add `https://github.com/tomasf/NavLibSwift.git` as a dependency in your project/package and `import NavLib`.
2. Enable C++ interoperability for your target.

### Initialize and Use a NavLibSession

1. Create an instance of `NavLibSession`.
2. Make a class conform to the `NavLibStateProvider` protocol. `modelBoundingBox` and `cameraTransform` are the only two required properties; the rest have defaults.
3. Call `NavLibSession`'s `start(stateProvider:applicationName:)` method to initialize the session. This will throw an error if the framework is not installed.

If your application has multiple 3D views, you can create multiple `NavLibSession` instances. To activate a specific session, call `setAsActiveSession()`.

For a minimal working example, refer to the [`NavLibDemo`](https://github.com/tomasf/NavLibDemo) repository, which demonstrates basic integration with SceneKit.

## Background

3DConnexion's macOS support is inconsistent, and documentation is sparse. Their developer forums are also relatively inactive. There are a few ways to add SpaceMouse support on macOS:

### HID

SpaceMouse devices use the HID protocol, so you can connect to them via IOKit and read raw input values. However, this approach is impractical:
- If the user has installed 3DConnexion's drivers (which most will have), they block direct HID access.
- Correctly interpreting raw values varies between device models, adding complexity.

### 3DconnexionClient

The `3DconnexionClient` framework is the traditional way to interface with SpaceMouse devices. It wraps HID calls and provides some preprocessing, but:
- You still need to implement the actual 3D navigation logic yourself.
- It's tedious to work with and relies on outdated things like Pascal strings (!).

### 3DconnexionNavLib

`3DconnexionNavLib` is a more modern, high-level library. It manages 3D navigation for you. Instead of manually handling input data, you provide callbacks to read and write properties of your 3D environment, and the library takes care of the rest.

NavLibSwift wraps `3DconnexionNavLib` to provide a streamlined Swift interface. However, due to outdated headers that no longer compile with modern versions of Clang, modified headers are included in this Swift package.

## License

NavLibSwift is licensed under the MIT License. See the LICENSE file for details.

This project is an independent initiative and is not affiliated with or endorsed by 3DConnexion. All trademarks and registered trademarks are the property of their respective owners.
