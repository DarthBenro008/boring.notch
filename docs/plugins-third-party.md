# Third-party plugins (planned → in progress)

This document describes **how third-party plugins will work** for Custom Notch, and what is already in place vs still to build.

> **Product direction:** rich native SwiftUI in-process (signed `.cnplugin` bundles). Process isolation (XPC) is a later hardening phase—not required for the first third-party MVP.

---

## Status

| Item | Status |
|------|--------|
| Public **CustomNotchPluginSDK** package (API + versioning) | **Done** (`Packages/CustomNotchPluginSDK`) |
| `CNPluginFactory` ObjC entry base class | **Done** (SDK) |
| Bundle Info.plist key constants | **Done** (`PluginBundleKeys`) |
| First-party plugins via compile-time registration | **Done** |
| Scan / load `.cnplugin` from Application Support | **Not yet** |
| Settings Install / Uninstall UI | **Not yet** |
| Code-signature enforcement on load | **Not yet** |
| Example third-party Xcode project | **Not yet** |
| Marketplace / auto-update | **Out of scope** for v1 |

First-party plugin authoring remains: [docs/plugins.md](./plugins.md).

---

## Target install layout

```
~/Library/Application Support/custom.notch/Plugins/
  com.example.hello.cnplugin/
    Contents/
      Info.plist
      MacOS/
        HelloPlugin          # MH_BUNDLE / dylib
      Resources/
```

Sandboxed builds use the app container’s Application Support (same relative path).

---

## Bundle Info.plist (contract)

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `CFBundleIdentifier` | String | yes | Plugin id (`PluginID`) |
| `CFBundleName` | String | yes | Display name |
| `CFBundleShortVersionString` | String | yes | Plugin version |
| `CNPluginPrincipalClass` | String | yes | `@objc` name of `CNPluginFactory` subclass |
| `CNPluginSDKVersion` | Number | yes | **Major** SDK version (must match host `PluginSDKVersion.major`) |
| `CNPluginMinHostVersion` | String | recommended | Min Custom Notch version (semver) |
| `CNPluginCapabilities` | String | no | e.g. `network,wifiSSID` |
| `CNPluginSummary` | String | recommended | Settings blurb |
| `CNPluginAuthor` | String | recommended | Author |
| `CNPluginIconSystemName` | String | no | SF Symbol name |

See `PluginBundleKeys` and `PluginSDKVersion` in the SDK.

---

## Author workflow (when loader ships)

1. Depend on **CustomNotchPluginSDK** (SPM path or git tag for a release).
2. Implement `CustomNotchPlugin` (same API as first-party).
3. Subclass `CNPluginFactory`:

```swift
import CustomNotchPluginSDK

@objc(HelloThirdPartyFactory)
final class HelloThirdPartyFactory: CNPluginFactory {
    override class func createPlugin() -> Any {
        HelloThirdPartyPlugin()
    }
}
```

4. Set `CNPluginPrincipalClass` = `HelloThirdPartyFactory` (or module-qualified name as loaded).
5. Build a **Release** `.cnplugin`, codesign (Developer ID for distribution).
6. User installs via **Settings → Plugins → Install…** (planned); new plugins start **disabled** until enabled with capability consent.

### Compatibility

- Host refuses plugins whose `CNPluginSDKVersion` ≠ host major.
- Build plugins with the **same Xcode / Swift generation** noted in host release notes when possible (Swift modules are not forever-stable across toolchains).

---

## Security model (v1 target)

| Control | Policy |
|---------|--------|
| Signing | Release host: reject unsigned / invalid signatures before `Bundle.load` |
| Debug | Optional “allow unsigned plugins” for local development |
| Trust | Install ≠ enable; capability sheet on first enable |
| Library validation | Host may need `com.apple.security.cs.disable-library-validation` to load third-party signed code under hardened runtime — documented residual risk in SECURITY.md when enabled |
| Crash domain | Still **in-process** — a plugin can crash the app |

Not an App Store multi-plugin story without further isolation.

---

## License (read before publishing a plugin)

Custom Notch is **GPL-3.0**. Until stated otherwise, assume third-party plugins that link the SDK and load into the host should be **GPL-compatible**. This is product policy for the open launch—not a substitute for legal advice.

---

## Implementation roadmap (host)

| Phase | Work |
|-------|------|
| **0** | SDK extraction ← *current* |
| **1** | Loader + Install UI + signature checks + sample `.cnplugin` |
| **2** | Safe mode, team allowlist, crash breadcrumb |
| **3** | Optional XPC for high-risk capabilities |

---

## Developing against the SDK today

```bash
cd Packages/CustomNotchPluginSDK
swift test
```

First-party plugins in `customNotch/Plugins/BuiltIn/` already `import CustomNotchPluginSDK`.

When the loader lands, this file will be updated with install paths and a link to `Examples/SampleThirdPartyPlugin/`.
