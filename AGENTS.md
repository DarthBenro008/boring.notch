# AGENTS.md — Custom Notch

Guidance for humans and coding agents working in this repository.

## What this project is

**Custom Notch** (`custom.notch`) is a macOS menu-bar / notch companion app written in **SwiftUI + AppKit**. It draws a custom window over the MacBook notch (or menu-bar area on non-notch displays) and expands it into a control surface for:

- Music playback (Now Playing, Apple Music, Spotify, YouTube Music)
- Calendar / reminders
- File shelf (drag-and-drop + AirDrop / share)
- System HUD replacements (volume, brightness, keyboard backlight)
- Battery / charging live activity
- Webcam mirror
- Settings and onboarding
- **First-party plugins** (tabs, chips, menus, settings — see [docs/plugins.md](./docs/plugins.md))

This repository is a **fork and rebrand** of [Boring Notch](https://github.com/TheBoredTeam/boring.notch) by The Bored Team. Upstream credit lives in `README.md` only — do **not** reintroduce upstream product branding into UI, bundle IDs, or marketing copy. Product feature status and roadmap live in `README.md`.

## Branding rules

| Item | Value |
|------|--------|
| Product name | Custom Notch |
| Repo / project slug | `custom.notch` |
| Xcode project | `customNotch.xcodeproj` |
| App target / scheme | `customNotch` |
| App bundle ID | `customnotch.customnotch` |
| XPC helper target | `CustomNotchXPCHelper` |
| XPC bundle ID | `customnotch.customnotch.CustomNotchXPCHelper` |
| Display name | Custom Notch |

When adding user-facing strings, use **Custom Notch** / **custom.notch**, never Boring Notch / boring.notch / The Bored Team (except README acknowledgments).

## Repository layout

```
custom.notch/
├── AGENTS.md                 # This file (agents / architecture)
├── README.md                 # Product overview, features, roadmap
├── docs/
│   ├── plugins.md              # First-party plugin authoring + limitations
│   └── plugins-third-party.md  # Third-party bundles (planned/in progress)
├── CONTRIBUTING.md
├── SECURITY.md
├── LICENSE                   # GPL-3.0
├── Packages/
│   ├── CustomNotchPluginSDK/ # Public plugin API (import CustomNotchPluginSDK)
│   └── NotchPluginCore/      # WiZ/audio pure logic (swift test)
├── customNotch.xcodeproj/
├── customNotch/              # Main app sources
│   ├── Plugins/              # Host + built-in plugins (file-synced; no SDK copies)
│   ├── components/ managers/ MediaControllers/ …
│   └── …
├── CustomNotchXPCHelper/
├── Configuration/dmg/
├── mediaremote-adapter/
├── updater/appcast.xml
└── .github/workflows/
```

## Architecture (mental model)

### Process & windows

1. `DynamicNotchApp` (`customNotchApp.swift`) owns Sparkle updater wiring and the menu bar extra.
2. `AppDelegate` creates one notch window per display (or a single primary window, depending on settings), each backed by a `CustomViewModel`.
3. Windows are specialized AppKit types:
   - `CustomNotchWindow` — standard notch window
   - `CustomNotchSkyLightWindow` — elevated / special space presentation (SkyLight)
4. `ContentView` is the SwiftUI root: closed vs open notch chrome, hover, gestures, live activities, and tab content.

### State

| Type | Role |
|------|------|
| `CustomViewModel` | Per-window notch geometry, open/closed state, drop targeting, camera UI |
| `CustomViewCoordinator` | App-wide UI coordinator: tabs, sneak peeks / HUD pulses, first-launch flags |
| `Defaults` keys in `models/Constants.swift` | Persisted user preferences (sindresorhus/Defaults) |
| Managers (`MusicManager`, `CalendarManager`, …) | Shared services, typically `.shared` singletons |

Prefer extending existing coordinators/managers over inventing parallel global state.

### Media

- `MusicManager` selects a `MediaControllerProtocol` implementation based on `Defaults[.mediaController]`.
- Controllers live under `MediaControllers/` (Now Playing via MediaRemote adapter, Apple Music, Spotify, YouTube Music).
- On newer macOS, Now Playing may be deprecated; default controller logic lives in `Constants.swift` (`defaultMediaController`).

### Shelf

Under `components/Shelf/`:

- **Models** — items, bookmarks
- **ViewModels** — selection, item, shelf state
- **Services** — drop, persistence, thumbnails, Quick Look, share / AirDrop
- **Views** — shelf UI and drag previews

### System integration

- **Media keys / HUD:** `observers/MediaKeyInterceptor.swift`, `VolumeManager`, `BrightnessManager`
- **Fullscreen hide:** `FullscreenMediaDetection` + MacroVisionKit
- **Accessibility XPC:** `CustomNotchXPCHelper` + `XPCHelperClient` (service name must match bundle ID)
- **Calendar:** EventKit via `CalendarManager` / providers

## Development setup

### Prerequisites

- macOS (Sonoma 14+ to run; newer recommended for Xcode)
- Xcode 16+
- Apple Silicon or Intel

### Open & run

```bash
open customNotch.xcodeproj
```

Select scheme **customNotch**, destination **My Mac**, then Run (`Cmd+R`).

First-run flows may request calendar, accessibility, and automation permissions depending on features enabled.

### Configuration you must own on a fork

1. **Bundle IDs** — already set to `customnotch.customnotch` (+ XPC suffix). Change only if you need a unique ID for your Apple Developer team.
2. **Signing** — set your Development Team in Xcode (Signing & Capabilities).
3. **Sparkle updates** — `customNotch/Info.plist` has placeholder `SUFeedURL` / `SUPublicEDKey` from rebranding. Generate **your own** Sparkle EdDSA keys before shipping auto-update; do not reuse upstream keys.
4. **GitHub URLs** — in-app “GitHub” buttons and docs use `YOUR_USERNAME` placeholders; replace with your fork URL.
5. **Homebrew / release workflow** — `.github/workflows/release.yml` publishes to `${{ github.repository_owner }}/homebrew-custom-notch` when secrets are present; create that tap only if you need it.

## Coding conventions

- **SwiftUI-first UI**, AppKit where windows, status items, or private window levels require it.
- Prefer `@MainActor` for UI-facing types; match existing isolation.
- User preferences: add keys to `Defaults.Keys` in `models/Constants.swift` with sensible defaults.
- New UI strings: add English entries to `Localizable.xcstrings` (do not hand-edit every locale unless necessary).
- File headers may still list original authors; that is fine for license history. New files should use project name `customNotch`.
- Avoid drive-by refactors; keep PRs focused.
- Do not commit secrets, certificates, or Sparkle private keys.

### Naming

- Types: `Custom*` or domain names (`MusicManager`, `ShelfView`)
- Prefer clarity over prefix spam for new domain types
- Product strings: “Custom Notch”

## Testing checklist (manual)

Automated UI tests are limited; before merging feature work, smoke-test:

- [ ] App launches; notch visible on primary display
- [ ] Hover opens / closes notch; settings still accessible from menu bar
- [ ] Music play/pause/skip with the configured media source
- [ ] Calendar tab (with permission)
- [ ] Shelf: drag a file in, open, share if relevant
- [ ] Volume/brightness HUD if “HUD replacement” is enabled
- [ ] Multi-display behavior if `showOnAllDisplays` is on
- [ ] Clean build of **customNotch** and **CustomNotchXPCHelper**

## CI & release

- **Build:** `.github/workflows/cicd.yml` builds scheme `customNotch` on macOS runners
- **CodeQL:** `.github/workflows/codeql.yml`
- **Release:** comment-driven release workflow packages a DMG via `Configuration/dmg/`
- **Appcast:** `updater/appcast.xml` is intentionally empty of upstream releases — append items when you ship signed builds

## License

GPL-3.0. Modifications must remain GPL-compatible. Preserve attribution for third-party code listed in `THIRD_PARTY_LICENSES` and for upstream Boring Notch in the README.

## Plugin system

**Canonical guides:**  
- First-party: [docs/plugins.md](./docs/plugins.md)  
- Third-party (planned loader): [docs/plugins-third-party.md](./docs/plugins-third-party.md)

Summary for agents:

- Prefer **plugins** for optional features instead of growing `ContentView` switches.
- Plugins are **in-process** (same sandbox/crash domain). Public API lives in **`import CustomNotchPluginSDK`**.
- Register first-party types in `PluginManager.registerBuiltIns()`; implement `CustomNotchPlugin`.
- Template: `Plugins/BuiltIn/HelloSample/HelloSamplePlugin.swift`.
- `Plugins/` is file-system-synced (host code only). Do **not** re-add SDK sources under `Plugins/SDK/`.
- Tests: `Packages/CustomNotchPluginSDK` + `Packages/NotchPluginCore` → `swift test`.
- Host services: `NetworkPathMonitorService`, `WiFiSSIDMonitor` (SSID only to `.wifiSSID` plugins).
- Third-party load path is **not** implemented yet; SDK has `CNPluginFactory`, `PluginSDKVersion`, `PluginBundleKeys` for the upcoming loader.

### Built-in plugins

| Plugin | ID | Default |
|--------|-----|---------|
| Hello Sample | `custom.notch.plugin.hello` | on |
| Audio Output | `custom.notch.plugin.audio` | on |
| WiZ Desk Lamp | `custom.notch.plugin.wiz` | off |

### Host wiring (quick map)

| Concern | Location |
|---------|----------|
| Bootstrap | `AppDelegate` → `PluginManager.shared.bootstrap()` |
| Tabs | `TabSelectionView` ← `PluginRegistry.orderedPanels` |
| Open panel | `ContentView` → `PluginPanelHostView` |
| Closed chip | `PluginRegistry.activeLiveActivity()` in closed-notch chain |
| Settings | `PluginsSettingsView` |
| Extras menu | `CustomExtrasMenu` ← `PluginRegistry.menuItems` |

## Useful entry points for new features

| Feature area | Start here |
|--------------|------------|
| Notch chrome / open-close | `ContentView.swift`, `CustomViewModel`, `sizing/matters.swift` |
| New settings pane | `components/Settings/SettingsView.swift` |
| New live activity (built-in) | `components/Live activities/`, `CustomViewCoordinator` |
| New media source | `MediaControllers/` + `MediaControllerType` + `MusicManager` |
| Shelf behavior | `components/Shelf/` |
| **New optional feature** | **Plugin** — [docs/plugins.md](./docs/plugins.md) + Hello Sample |
| Permissions / onboarding | `components/Onboarding/` |
| Keyboard shortcuts | `Shortcuts/ShortcutConstants.swift` |

When in doubt, mirror an adjacent feature or the Hello Sample plugin rather than inventing a new architecture.
