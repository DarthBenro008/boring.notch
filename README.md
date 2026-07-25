<h1 align="center">
  <br>
  Custom Notch
  <br>
</h1>

<p align="center">
  <em>A customizable MacBook notch control center — music, calendar, shelf, HUDs, and first-party plugins.</em>
</p>

<p align="center">
  <strong>Status:</strong> active development · macOS 14+ · GPL-3.0
</p>

---

## Credits & shoutout

**Custom Notch** is a fork of **[Boring Notch](https://github.com/TheBoredTeam/boring.notch)** by **[The Bored Team](https://github.com/TheBoredTeam)**.

Huge thanks to everyone who built and maintained the original project — its architecture and polish made this fork possible.

- **Upstream:** [TheBoredTeam/boring.notch](https://github.com/TheBoredTeam/boring.notch)
- **Website:** [theboring.name](http://theboring.name)

This fork rebrands the product, keeps the core experience, and adds a **plugin system** plus sample plugins for further customization.

---

## What it does

Custom Notch turns the MacBook notch (or the menu-bar strip on non-notch displays) into an interactive control surface:

| Feature | Status | Notes |
|---------|--------|--------|
| Music live activity + controls | **Stable** | Now Playing, Apple Music, Spotify, YouTube Music |
| Music visualizer | **Stable** | Built-in + custom visualizer options |
| Calendar / reminders in the notch | **Stable** | EventKit permissions required |
| File shelf + AirDrop / share | **Stable** | Drag-and-drop shelf |
| Charging / battery live activity | **Stable** | Plug events + percentage options |
| Webcam mirror | **Stable** | Optional camera preview |
| System HUD replacements | **Stable** | Volume, brightness, keyboard backlight (accessibility) |
| Gestures & multi-display | **Stable** | Hover, drop, per-display windows |
| Notch size customization | **Stable** | Match real notch / menu bar / custom |
| **Plugin system** | **Beta** | In-process Swift plugins; public SDK package |
| **CustomNotchPluginSDK** | **Beta** | Versioned API for first-party + future third-party |
| Hello Sample plugin | **Beta** | Template exercising all plugin surfaces |
| Audio Output plugin | **Beta** | Pick speakers / AirPods / outputs from the notch |
| WiZ Desk Lamp plugin | **Beta** | LAN UDP control + optional Wi‑Fi SSID automation |
| Third-party `.cnplugin` install | **Planned** | Loader + Install UI in progress — [docs](./docs/plugins-third-party.md) |

See **[docs/plugins.md](./docs/plugins.md)** (first-party) and **[docs/plugins-third-party.md](./docs/plugins-third-party.md)** (third-party).

<p align="center">
  <img src="https://github.com/user-attachments/assets/2d5f69c1-6e7b-4bc2-a6f1-bb9e27cf88a8" alt="Demo GIF" />
</p>

---

## Requirements

- **macOS 14 Sonoma** or later (to run)
- **Xcode 16+** recommended for development
- Apple Silicon or Intel Mac

---

## Quick start (build from source)

```bash
git clone https://github.com/YOUR_USERNAME/custom.notch.git
cd custom.notch
open customNotch.xcodeproj
```

1. Scheme: **customNotch** · Destination: **My Mac**
2. Set your Signing Team if prompted
3. **Run** (`Cmd + R`)

### Using the app

- Hover the notch to expand it
- Use **Home** for music / calendar / mirror (as enabled in Settings)
- Use plugin tabs (**Hello**, **Audio**, **Lamp**, …) when those plugins are enabled
- Menu bar **sparkle** icon → **Settings** for preferences and **Plugins**

### Gatekeeper (unsigned builds)

```bash
xattr -dr com.apple.quarantine /Applications/customNotch.app
```

---

## Plugins

Plugins are optional modules that add **tabs**, **closed-notch chips**, **menu actions**, **settings**, and **toasts** without forking core UI.

| Built-in plugin | Default | Description |
|-----------------|---------|-------------|
| Hello Sample | On | Learning template (all surfaces) |
| Audio Output | On | System audio output picker (Core Audio) |
| WiZ Desk Lamp | Off | Local WiZ bulb control (UDP); optional SSID automation |

**Developer docs:** [docs/plugins.md](./docs/plugins.md)  
**Agent / architecture notes:** [AGENTS.md](./AGENTS.md)

### Plugin system limitations (summary)

- Plugins run **in-process** (same sandbox and crash domain as the app)
- **Third-party install/load** is not finished yet (SDK is ready; see third-party doc)
- Surfaces are **tab / chip / menu / settings / toast** — not free-form Home layout
- Only **one** closed-notch live activity wins at a time
- Wi‑Fi SSID automation needs **Location** permission and may be unavailable on Ethernet

Full list: [Limitations](./docs/plugins.md#limitations-read-this) · [Third-party plan](./docs/plugins-third-party.md)

### Unit tests

```bash
cd Packages/CustomNotchPluginSDK && swift test   # public plugin API
cd Packages/NotchPluginCore && swift test      # WiZ / audio helpers
```

---

## Roadmap

Focused on this fork’s direction (not a dump of every upstream wishlist item).

### Now / next

- [ ] **Third-party `.cnplugin` loader** (scan Application Support, signature checks, Install UI)
- [ ] Example third-party plugin project + author docs
- [ ] Plugin polish: empty states, tab overflow, safer re-registration helpers
- [ ] WiZ: optional discovery / multi-bulb support
- [ ] Audio: hot-plug device refresh
- [ ] Safe mode / last-plugin crash breadcrumb (for third-party)

### Later

- [ ] Team-ID allowlist and stronger trust UX
- [ ] Home-row plugin widgets (tiles without a full tab)
- [ ] Weather or Bluetooth live activities (as plugins)
- [ ] Optional XPC isolation for high-risk capabilities
- [ ] Marketplace / auto-update (not committed)

### Done (baseline)

- [x] Core notch UX from upstream (music, calendar, shelf, HUDs, battery, mirror, gestures)
- [x] Rebrand to Custom Notch
- [x] Plugin host + Settings UI + first-party samples
- [x] `NotchPluginCore` pure logic + unit tests
- [x] **`CustomNotchPluginSDK` public package** (API v1, factory entry, bundle keys)

---

## Development

| Doc | Audience |
|-----|----------|
| [docs/plugins.md](./docs/plugins.md) | Writing plugins |
| [AGENTS.md](./AGENTS.md) | Repo architecture for humans & coding agents |
| [CONTRIBUTING.md](./CONTRIBUTING.md) | PR workflow |
| [SECURITY.md](./SECURITY.md) | Vulnerability reporting |

```bash
# Build the app (CLI)
xcodebuild -project customNotch.xcodeproj -scheme customNotch \
  -configuration Debug -destination 'platform=macOS' build
```

---

## Acknowledgments

- **[Boring Notch](https://github.com/TheBoredTeam/boring.notch)** / **[The Bored Team](https://github.com/TheBoredTeam)** — original app
- **[MediaRemoteAdapter](https://github.com/ungive/mediaremote-adapter)** — Now Playing on newer macOS
- **[NotchDrop](https://github.com/Lakr233/NotchDrop)** — early Shelf inspiration

Third-party licenses: [THIRD_PARTY_LICENSES](./THIRD_PARTY_LICENSES).

---

## License

**GNU General Public License v3.0** — see [LICENSE](./LICENSE).
