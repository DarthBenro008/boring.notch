# CustomNotchPluginSDK

Public, versioned API for Custom Notch plugins (first-party and future third-party `.cnplugin` bundles).

## Version

See `PluginSDKVersion` (`major.minor.patch`). Third-party bundles declare major via `CNPluginSDKVersion` in Info.plist.

## Product

```swift
dependencies: [
  .package(path: "…/Packages/CustomNotchPluginSDK")
]
// or git tag once published
```

```swift
import CustomNotchPluginSDK
```

## Entry points

- **First-party (in-app):** implement `CustomNotchPlugin`, register type in host `PluginManager`.
- **Third-party (planned loader):** subclass `CNPluginFactory`, override `createPlugin()`, set `CNPluginPrincipalClass` in the `.cnplugin` Info.plist.

## Docs

- [Plugin development (first-party)](../../docs/plugins.md)
- Third-party loading is planned; see host repo roadmap / `docs/plugins-third-party.md` when present.

## Tests

```bash
cd Packages/CustomNotchPluginSDK && swift test
```
