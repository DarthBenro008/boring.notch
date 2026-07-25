# Plugin development guide

Custom Notch can be extended with **in-process Swift plugins**. Plugins register UI surfaces and react to host events through a small host API — they do not own the notch window themselves.

This document covers how to write a plugin, what the system can and cannot do, and how to test.

---

## Status

| Area | Status |
|------|--------|
| Plugin host API (panels, live activities, menus, settings, sneak peeks) | **Available** |
| Built-in plugins (Hello, Audio Output, WiZ Lamp) | **Available** |
| Enable/disable + per-plugin settings in **Settings → Plugins** | **Available** |
| Host events (launch, notch open/close, network path, Wi‑Fi SSID) | **Available** |
| First-party plugins (compiled into the app) | **Supported** |
| Public **CustomNotchPluginSDK** package | **Supported** (`Packages/CustomNotchPluginSDK`, major **1**) |
| Third-party installable `.cnplugin` bundles | **In progress** — see [plugins-third-party.md](./plugins-third-party.md) |
| Process isolation / XPC plugins | **Not supported** (later phase) |
| Scripting (JS/Lua) | **Not supported** |

---

## Concepts

```
┌─────────────────────────────────────────────────────────┐
│  customNotch (host app)                                  │
│                                                          │
│  PluginManager  → activates enabled plugins              │
│  PluginRegistry → panels, menus, live activities, …      │
│  PluginHost     → API handed to each plugin              │
│                                                          │
│  Surfaces:                                               │
│    • Open-notch tab (panel)                              │
│    • Closed-notch live activity chip                     │
│    • Extras menu actions                                 │
│    • Settings detail page                                │
│    • Sneak-peek toast                                    │
└─────────────────────────────────────────────────────────┘
```

A plugin is a class conforming to `CustomNotchPlugin`:

```swift
@MainActor
public protocol CustomNotchPlugin: AnyObject {
    static var metadata: PluginMetadata { get }
    init()
    func activate(host: PluginHost) async
    func deactivate() async
}
```

During `activate(host:)`, call host methods to register UI and subscribe to events. During `deactivate()`, cancel subscriptions and release resources.

---

## Surfaces (what you can build)

| Host API | User-facing effect |
|----------|--------------------|
| `registerPanel(_:)` | New **tab** when the notch is open |
| `registerLiveActivity(_:)` | Compact **chip** when the notch is closed (competes by priority) |
| `registerMenuItems(_:)` | Buttons in the notch **extras** area |
| `registerSettings(_:)` | Detail UI under **Settings → Plugins** |
| `showSneakPeek(_:)` | Short toast on the closed notch |
| `openNotch(to:)` / `closeNotch()` | Expand or collapse the notch |
| `subscribe { event in … }` | Lifecycle / environment events |
| `storage` | Namespaced key-value prefs for this plugin |
| `logger` | OSLog category `plugin.<id>` |

### Host events

```swift
public enum HostEvent {
    case didLaunch
    case willTerminate
    case notchDidOpen
    case notchDidClose
    case preferredDisplayChanged(uuid: String?)
    case networkPathChanged(isSatisfied: Bool)
    case wifiSSIDChanged(ssid: String?)  // only if metadata declares .wifiSSID
    case tick(Date)                      // reserved; not heavily used yet
}
```

Wi‑Fi SSID events are delivered **only** to plugins whose metadata includes capability `.wifiSSID`. Reading SSID requires **Location** permission on modern macOS.

### Capabilities

Declare what the plugin needs in `PluginMetadata.capabilities`:

| Capability | Meaning |
|------------|---------|
| `.network` | Outbound network (documented for Settings UI) |
| `.wifiSSID` | Subscribe to SSID changes (Location + CoreWLAN host service) |
| `.notifications` | Reserved for future use |
| `.localNetwork` | Reserved (Bonjour / local discovery) |

Capabilities are informational + gated for SSID. They do not open holes in the App Sandbox; the host app’s entitlements still apply to all plugins.

---

## Layout on disk

```
Packages/CustomNotchPluginSDK/   # Public plugin API (import CustomNotchPluginSDK)
Packages/NotchPluginCore/        # Shared WiZ/audio logic + unit tests

customNotch/Plugins/
├── PluginManager.swift          # Registration + lifecycle
├── PluginRegistry.swift
├── PluginHostImpl.swift         # Host implements PluginHost
├── HostServices/
├── Surfaces/
└── BuiltIn/
    ├── HelloSample/             # Reference — start here
    ├── AudioOutput/
    └── WizLamp/
```

`Plugins/` (host code) is a file-system-synced Xcode group. The **SDK** is an SPM package linked into the app; third parties will depend on the same package without linking the app.

---

## Step-by-step: add a built-in plugin

### 1. Create the plugin type

Create `customNotch/Plugins/BuiltIn/MyFeature/MyFeaturePlugin.swift`:

```swift
import CustomNotchPluginSDK
import SwiftUI

@MainActor
final class MyFeaturePlugin: CustomNotchPlugin {
    static let metadata = PluginMetadata(
        id: PluginID("custom.notch.plugin.myfeature"),
        name: "My Feature",
        version: "1.0.0",
        author: "You",
        summary: "One-line description for Settings.",
        iconSystemName: "star.fill",
        capabilities: [],           // e.g. [.network]
        defaultEnabled: false
    )

    private var host: PluginHost?
    private var subscription: PluginEventSubscription?

    func activate(host: PluginHost) async {
        self.host = host

        host.registerPanel(
            PluginPanelSpec(
                title: "My Feature",
                systemImage: "star.fill",
                sortOrder: 60
            ) {
                AnyView(
                    Text("Hello from My Feature")
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
            }
        )

        host.registerMenuItems([
            PluginMenuItem(id: "ping", title: "Ping", systemImage: "bell") {
                host.showSneakPeek(
                    PluginSneakPeek(title: "Ping!", systemImage: "bell.fill")
                )
            }
        ])

        subscription = host.subscribe { event in
            if case .notchDidOpen = event {
                host.logger.debug("Notch opened")
            }
        }
    }

    func deactivate() async {
        subscription?.cancel()
        subscription = nil
        host = nil
    }
}
```

Use **reverse-DNS** IDs: `custom.notch.plugin.<name>`.

### 2. Register it

In `PluginManager.registerBuiltIns()`:

```swift
register(type: MyFeaturePlugin.self)
```

### 3. Build and enable

1. Run scheme **customNotch**.
2. Open **Settings → Plugins**.
3. Enable **My Feature** (if `defaultEnabled` is `false`).
4. Open the notch — your tab and menu actions should appear.

### 4. Optional: shared logic + tests

Put pure (non-UI) logic in `Packages/NotchPluginCore` when you want unit tests without launching the app:

```bash
cd Packages/NotchPluginCore
swift test
```

App plugins import `NotchPluginCore` (already linked to the app target).

---

## Patterns that work well

### Persistence

```swift
host.storage.set("value", forKey: "apiKey")
let key = host.storage.string(forKey: "apiKey")
```

Keys are automatically namespaced per plugin ID. Do not store secrets in source; use storage or Keychain for real credentials.

### Refreshing UI after state changes

Registration is snapshot-based. After changing state that affects menu titles or live activity content, **re-register** the relevant surfaces and notify the registry:

```swift
host.registerMenuItems([/* updated items */])
PluginRegistry.shared.objectWillChange.send()
```

See `HelloSamplePlugin`, `AudioOutputPlugin`, and `WizLampPlugin` for full patterns.

### Live activity priority

Only **one** closed-notch activity wins at a time (same as built-in music/battery behavior). Higher `priority` wins among active plugin activities; system battery expansion and sneak peeks still outrank plugins.

Suggested ranges:

| Priority | Use |
|----------|-----|
| 50–100 | Important transient state (e.g. lamp on) |
| 30–49 | Ambient status (e.g. current audio output) |
| &lt; 30 | Low priority demos |

### Settings UI

Prefer simple `VStack` / controls for `registerSettings` content. Avoid nesting a full `Form` inside the Plugins settings form if it causes layout issues; match `HelloSampleSettingsView`.

---

## Limitations (read this)

### Security & process model

1. **In-process only.** Plugins run inside `customNotch.app` with the **same sandbox, entitlements, and crash domain** as the host. A bad plugin can freeze or crash the whole app.
2. **Third-party loading is not finished.** The public SDK and factory entry exist; install/load of `.cnplugin` bundles is still landing — see [plugins-third-party.md](./plugins-third-party.md). Until then, ship features as first-party plugins in this repo.
3. **No capability sandbox per plugin.** Declared capabilities guide Settings copy and SSID delivery; they do not isolate filesystem or network beyond the app sandbox.

### UI & UX constraints

4. **Fixed open-notch chrome.** Plugins get a **tab + panel**, not arbitrary layout in the Home music/calendar row (no home widgets yet).
5. **One closed live activity at a time.** Plugins compete with each other and with built-in music presentation.
6. **Limited space.** Design for ~640×190 open notch size; use scrolling for long lists (`AudioOutputPlugin` does this).
7. **`AnyView` at the boundary.** Panel/live activity builders are type-erased; keep those views simple.
8. **Extras menu is compact.** A few actions are fine; large menus will feel cramped.

### Platform & APIs

9. **Host API is small.** Plugins cannot access `AppDelegate`, private window handles, or arbitrary managers unless you extend `PluginHost` intentionally.
10. **Wi‑Fi SSID is best-effort.** Requires Location permission; may be `nil` offline, on Ethernet, or if denied.
11. **WiZ control is LAN UDP**, not cloud OAuth. Bulb must be reachable on the local network; discovery is not built in (configure IP manually).
12. **Audio output** uses Core Audio defaults; exotic multi-output / aggregate routing may be incomplete.
13. **No plugin-provided HUD replacement** for volume/brightness keys (host still owns media key interceptor).
14. **No App Store–style marketplace** yet. Signing of third-party plugins will be required for Release loads once the loader ships; there is still no store or auto-update.

### Licensing

15. Project is **GPL-3.0**. First-party plugins in this tree are fine. If you later add third-party loadable plugins, treat license obligations carefully (dynamic linking / derivative works).

---

## Built-in plugins (reference)

| Plugin | ID | Default | Role |
|--------|-----|---------|------|
| Hello Sample | `custom.notch.plugin.hello` | On | Full surface template |
| Audio Output | `custom.notch.plugin.audio` | On | System output device picker |
| WiZ Desk Lamp | `custom.notch.plugin.wiz` | Off | LAN lamp control + optional SSID automation |

Copy **Hello Sample** when learning; copy **Audio** / **WiZ** when you need Core Audio or networked devices.

---

## Testing checklist (for a new plugin)

- [ ] Plugin appears under **Settings → Plugins** with correct name/summary
- [ ] Enable → surfaces appear without restart (activate path)
- [ ] Disable → tabs/menus disappear (deactivate + clear surfaces)
- [ ] Panel usable at open-notch size; no clipped controls without scroll
- [ ] Sneak peeks dismiss cleanly
- [ ] Live activity (if any) does not permanently block music when inactive (`isActive` returns false)
- [ ] Storage survives quit/relaunch
- [ ] `swift test` green if you added `NotchPluginCore` logic
- [ ] App still builds: scheme **customNotch**, destination **My Mac**

### Commands

```bash
# App build
xcodebuild -project customNotch.xcodeproj -scheme customNotch \
  -configuration Debug -destination 'platform=macOS' build

# Plugin core unit tests
cd Packages/NotchPluginCore && swift test
```

---

## Extending the host (advanced)

If plugins need a new capability (e.g. clipboard, weather), prefer:

1. Add a method or event on `PluginHost` / `HostEvent`
2. Implement in `PluginHostImpl` using existing managers
3. Document capability flags and privacy implications
4. Avoid giving plugins raw access to private APIs

Do **not** reintroduce large `switch` statements in `ContentView` for optional features — keep optional work in plugins.

---

## Related docs

- [plugins-third-party.md](./plugins-third-party.md) — third-party bundles, signing, roadmap
- [AGENTS.md](../AGENTS.md) — architecture for coding agents
- [README.md](../README.md) — product overview and roadmap
- [Packages/CustomNotchPluginSDK/README.md](../Packages/CustomNotchPluginSDK/README.md) — public SDK
- [Packages/NotchPluginCore/README.md](../Packages/NotchPluginCore/README.md) — WiZ/audio pure logic tests
